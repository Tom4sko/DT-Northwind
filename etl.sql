CREATE DATABASE PEACOCK_NORTHWIND_DB;
USE PEACOCK_NORTHWIND_DB;
CREATE SCHEMA PEACOCK_NORTHWIND_DB.staging;
USE SCHEMA PEACOCK_NORTHWIND_DB.staging;

CREATE TABLE categories_staging
(      
    categoryid INTEGER PRIMARY KEY,
    categoryname VARCHAR(25),
    description VARCHAR(255)
);

CREATE TABLE customers_staging
(      
    customerid INTEGER PRIMARY KEY,
    customername VARCHAR(50),
    contactname VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(20),
    postalcode VARCHAR(10),
    country VARCHAR(15)
);

CREATE TABLE employees_staging
(
    employeeid INTEGER PRIMARY KEY,
    lastname VARCHAR(15),
    firstname VARCHAR(15),
    birthdate DATETIME,
    photo VARCHAR(25),
    notes VARCHAR(1024)
);

CREATE TABLE shippers_staging
(
    shipperid INTEGER PRIMARY KEY,
    shippername VARCHAR(25),
    phone VARCHAR(15)
);

CREATE TABLE suppliers_staging
(
    supplierid INTEGER PRIMARY KEY,
    suppliername VARCHAR(50),
    contactname VARCHAR(50),
    address VARCHAR(50),
    city VARCHAR(20),
    postalcode VARCHAR(10),
    country VARCHAR(15),
    phone VARCHAR(15)
);

CREATE TABLE products_staging
(
    productid INTEGER PRIMARY KEY,
    productname VARCHAR(50),
    supplierid INTEGER,
    categoryid INTEGER,
    unit VARCHAR(25),
    price NUMERIC,
    FOREIGN KEY (categoryid) REFERENCES categories (categoryid),
    FOREIGN KEY (supplierid) REFERENCES suppliers (supplierid)
);

CREATE TABLE orders_staging
(
    orderid INTEGER PRIMARY KEY,
    customerid INTEGER,
    employeeid INTEGER,
    orderdate DATETIME,
    shipperid INTEGER,
    FOREIGN KEY (employeeid) REFERENCES employees (employeeid),
    FOREIGN KEY (customerid) REFERENCES customers (customerid),
    FOREIGN KEY (shipperid) REFERENCES shippers (shipperid)
);

CREATE TABLE orderdetails_staging
(
    orderdetailid INTEGER PRIMARY KEY,
    orderid INTEGER,
    productid INTEGER,
    quantity INTEGER,
    FOREIGN KEY (orderid) REFERENCES orders (orderid),
    FOREIGN KEY (productid) REFERENCES products (productid)
);

CREATE OR REPLACE STAGE PEACOCK_NORTHWIND_DB_stage;

COPY INTO categories_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO customers_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_customers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO employees_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_employees.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO shippers_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_shippers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO suppliers_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_suppliers.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO products_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_products.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orders_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_orders.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO orderdetails_staging
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_orderdetails.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('DAY', orderdate)) AS dim_dateid,
    DATE_TRUNC('DAY', orderdate) AS date,
    EXTRACT(YEAR FROM orderdate) AS year,
    EXTRACT(MONTH FROM orderdate) AS month,
    EXTRACT(DAY FROM orderdate) AS day,
    CASE
        WHEN EXTRACT(DAYOFWEEK FROM orderdate) IN (6, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type
FROM orders_staging;

CREATE OR REPLACE TABLE dim_suppliers AS
SELECT DISTINCT
    supplierid AS dim_supplierid,
    suppliername AS supplier_name,
    contactname AS contact_name,
    city AS city,
    country AS country,
    phone AS phone
FROM suppliers_staging;

CREATE OR REPLACE TABLE dim_products AS
SELECT DISTINCT
    productid AS dim_productid,
    productname AS product_name,
    categoryid AS category_id,
    unit AS unit,
    price AS price
FROM products_staging;

CREATE OR REPLACE TABLE dim_customers AS
SELECT DISTINCT
    customerid AS dim_customerid,
    customername AS customer_name,
    contactname AS contact_name,
    city AS city,
    country AS country,
    postalcode AS postal_code
FROM customers_staging;

CREATE OR REPLACE TABLE dim_employees AS
SELECT DISTINCT
    employeeid AS dim_employeeid,
    firstname AS first_name,
    lastname AS last_name,
    birthdate AS birth_date,
    photo AS photo,
    notes AS notes
FROM employees_staging;

CREATE OR REPLACE TABLE dim_shippers AS
SELECT DISTINCT
    shipperid AS dim_shipperid,
    shippername AS shipper_name,
    phone AS phone
FROM shippers_staging;

CREATE OR REPLACE TABLE dim_categories AS
SELECT DISTINCT
    categoryid AS dim_categoryid,
    categoryname AS category_name,
    description AS description
FROM categories_staging;

CREATE OR REPLACE TABLE fact_orders AS
SELECT
    o.orderid AS fact_orderid,
    o.orderdate AS order_date,
    d.dim_dateid AS date_id,
    c.dim_customerid AS customer_id,
    e.dim_employeeid AS employee_id,
    s.dim_supplierid AS supplier_id,
    sh.dim_shipperid AS shipper_id,
    p.dim_productid AS product_id,
    p.category_id AS dim_categoryid,
    od.quantity AS quantity,
    p.price AS unit_price,
    od.quantity * p.price AS total_price
FROM orders o
JOIN orderdetails_staging od ON o.orderid = od.orderid
JOIN dim_date d ON DATE_TRUNC('DAY', o.orderdate) = d.date
JOIN dim_customers c ON o.customerid = c.dim_customerid
JOIN dim_products p ON od.productid = p.dim_productid
JOIN dim_suppliers s ON p.category_id = s.dim_supplierid
JOIN dim_employees e ON o.employeeid = e.dim_employeeid
JOIN dim_shippers sh ON o.shipperid = sh.dim_shipperid;

DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
