# ETL Proces pre Northwind Dataset

Northwind Dataset predstavuje vzorovú databázu, ktorá obsahuje údaje o predaji, produktoch, zákazníkoch, dodávateľoch a ďalších aspektoch obchodných operácií. Táto dokumentácia sa zameriava na analýzu rôznych trendov a výkonov na základe údajov extrahovaných z Northwind Dataset. Cieľom je identifikovať kľúčové poznatky o predaji, výkonnosti produktov, geografických trendoch a dodávateľoch, ktoré môžu pomôcť v optimalizácii obchodných procesov.

---

## Obsah

- [Nastavenie základnej databázy](#nastavenie-základnej-databázy)
- [ERD Diagram](#erd-diagram)
- [Dimenzionálne a faktové tabuľky](#dimenzionálne-a-faktové-tabuľky)
- [Ciele práce](#ciele-práce)
- [Záver](#záver)


---

# Nastavenie základnej databázy

Pre účely tejto analýzy bola vytvorená databáza s názvom PEACOCK_NORTHWIND_DB so štruktúrou schémy a tabuliek pre staging a analytické dáta.

```sql
CREATE DATABASE PEACOCK_NORTHWIND_DB;
USE PEACOCK_NORTHWIND_DB;
CREATE SCHEMA PEACOCK_NORTHWIND_DB.staging;
USE SCHEMA PEACOCK_NORTHWIND_DB.staging;
```

### Vyprázdnenie databázy

Pred načítaním nových údajov je potrebné odstrániť existujúce staging tabuľky. Tento postup zabezpečí, že nové údaje nebudú kolidovať so starými.

```sql
DROP TABLE IF EXISTS categories_staging;
DROP TABLE IF EXISTS customers_staging;
DROP TABLE IF EXISTS employees_staging;
DROP TABLE IF EXISTS shippers_staging;
DROP TABLE IF EXISTS suppliers_staging;
DROP TABLE IF EXISTS products_staging;
DROP TABLE IF EXISTS orders_staging;
DROP TABLE IF EXISTS orderdetails_staging;
```

### Načítanie údajov pomocou COPY INTO

Dáta boli do staging tabuliek načítané z CSV súborov uložených v cloudovom úložisku pomocou nasledujúceho príkazu:

```sql
COPY INTO Categories
FROM @PEACOCK_NORTHWIND_DB_stage/northwind_table_categories.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

Tento príkaz zabezpečí korektné načítanie údajov z CSV do tabuľky Categories. Rovnako boli načítané aj ostatné tabuľky.

---

# ERD Diagram

ERD (Entity-Relationship Diagram) znázorňuje hlavné entity, ich atribúty a vzťahy v databáze pre dataset Northwind. Nižšie nájdete podrobný popis kľúčových entít a ich vzťahov:

![Northwind_ERD](https://github.com/user-attachments/assets/ffd2d153-9a0e-498c-abd2-93b55f456b4b)

*Entity-Relationship Diagram (ERD) pre databázu Northwind.*

Týmto spôsobom popis nebude rušivý, ale stále poskytne potrebné informácie. Ak by ste chceli 

---

# Dimenzionálne a faktové tabuľky
Dimenzionálny model bol vytvorený vo forme hviezdicového modelu (star schema), ktorý poskytuje vysokú efektivitu pri analýze obchodných dát. Hlavným prvkom modelu je faktová tabuľka fact_orders, ktorá je prepojená s týmito dimenziami:

* ```dim_products```: Obsahuje detaily o produktoch, ako sú ich názvy, kategórie a ceny.
* ```dim_categories```: Obsahuje názvy kategórii.
* ```dim_customers```: Uchováva demografické informácie o zákazníkoch vrátane ich adries a krajín.
* ```dim_employees```: Zaznamenáva údaje o zamestnancoch zodpovedných za spracovanie objednávok.
* ```dim_suppliers```: Informácie o dodávateľoch a ich lokalitách.
* ```dim_shippers```: Podrobnosti o prepravcoch, ktorí zabezpečujú doručenie objednávok.
* ```dim_date```: Kalendárne informácie o objednávkach, ako sú dni, mesiace a roky.
* ```fact_orders```: Slúži ako hlavná tabuľka faktov v dátovom sklade, ktorá zhromažďuje a uchováva všetky údaje týkajúce sa objednávok.


![DIM](https://github.com/user-attachments/assets/6cfd58ea-4404-456c-80f5-8c5ac6e4b69c)

*Schéma dimenzionálneho modelu (hviezdicového modelu) pre databázu Northwind.*

### dim_date

* Táto dimenzia slúži na ukladanie dátumových informácií, ako sú rok, mesiac, deň a typ dňa (víkend vs. pracovný deň). Vytvára sa pomocou dátumu objednávky (```orderdate```) z tabuľky ```orders_staging```.
* Typ: ```SCD Type 0```.

```sql
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
```

### dim_suppliers

* Táto dimenzia obsahuje údaje o dodávateľoch, ako sú názov dodávateľa, kontaktná osoba, mesto, krajina a telefónne číslo. Dátové zdroje pochádzajú z tabuľky ```suppliers_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_suppliers AS
SELECT DISTINCT
    supplierid AS dim_supplierid,
    suppliername AS supplier_name,
    contactname AS contact_name,
    city AS city,
    country AS country,
    phone AS phone
FROM suppliers_staging;
```

### dim_products

* Obsahuje informácie o produktoch vrátane názvu, kategórie, jednotiek (balenie, hmotnosť) a ceny. Dáta pochádzajú z tabuľky ```products_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_products AS
SELECT DISTINCT
    productid AS dim_productid,
    productname AS product_name,
    categoryid AS category_id,
    unit AS unit,
    price AS price
FROM products_staging;
```

### dim_customers

* Táto tabuľka je dimenziou zákazníkov. Obsahuje údaje o zákazníkoch, ako sú názov, kontaktná osoba, lokalita (mesto, krajina) a poštové smerovacie číslo. Zdrojom sú dáta z ```customers_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_customers AS
SELECT DISTINCT
    customerid AS dim_customerid,
    customername AS customer_name,
    contactname AS contact_name,
    city AS city,
    country AS country,
    postalcode AS postal_code
FROM customers_staging;
```

### dim_employees

* Táto dimenzia obsahuje údaje o zamestnancoch, ako sú meno, priezvisko, dátum narodenia, fotografia a poznámky. Tieto údaje pochádzajú z tabuľky ```employees_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_employees AS
SELECT DISTINCT
    employeeid AS dim_employeeid,
    firstname AS first_name,
    lastname AS last_name,
    birthdate AS birth_date,
    photo AS photo,
    notes AS notes
FROM employees_staging;
```

### dim_shippers

* Obsahuje informácie o prepravcoch, ako sú názov prepravcu a telefónne číslo. Dáta pochádzajú z tabuľky ```shippers_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_shippers AS
SELECT DISTINCT
    shipperid AS dim_shipperid,
    shippername AS shipper_name,
    phone AS phone
FROM shippers_staging;
```

### dim_categories

* Táto dimenzia ukladá kategórie produktov, obsahuje názov kategórie a jej popis. Dáta sú získané z tabuľky ```categories_staging```.
* Typ: ```SCD Type 1```.

```sql
CREATE OR REPLACE TABLE dim_categories AS
SELECT DISTINCT
    categoryid AS dim_categoryid,
    categoryname AS category_name,
    description AS description
FROM categories_staging;
```

### fact_orders

* Faktová tabuľka objednávok uchováva transakčné údaje, ako sú ID objednávky, dátum objednávky, zákazník, zamestnanec, dodávateľ, produkt, kategória, množstvo, jednotková cena a celková cena. Táto tabuľka je kľúčová pre analýzu a vzniká spojením dimenzií (napr. ```dim_date```, ```dim_customers```) s faktickými dátami z ```orders``` a ```orderdetails_staging```.
* Táto štruktúra podporuje efektívnu analýzu predaja, dodávateľov a kategórií produktov.
* Typ: Nepoužíva sa typ SCD.

```sql
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
```

---

# Ciele práce

### 1. Výkonnosť produktov

Analyzovali sme najpredávanejšie produkty a produkty s nižším predajom, aby sme pochopili, ktoré položky generujú najväčší objem predaja a ktoré potrebujú zlepšenia. Na základe týchto údajov môžeme implementovať potrebné úpravy produktového portfólia a marketingových stratégií.

* Najpredávanejšie produkty nám poskytujú prehľad o najpopulárnejších produktoch, ktoré najviac prispievajú k tržbám.
* Produkty s nižším predajom môžu byť predmetom ďalšej analýzy, kde navrhneme opatrenia na zlepšenie predaja, napríklad zlepšením ich viditeľnosti alebo úpravou cenovej politiky.
  
![vykonostproduktov1](https://github.com/user-attachments/assets/1c53b3ba-b010-492d-a16d-32090d685445)

*Graf najpredávanejších priduktov*

```sql
SELECT 
    p.ProductName,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales DESC
LIMIT 10;
```

![vykonostproduktov2](https://github.com/user-attachments/assets/399993cd-5b12-4f7a-9832-d5d22ee11ee0)

*Graf najmenej priduktov*

```sql
SELECT 
    p.ProductName,
    SUM(f.Quantity) AS TotalQuantitySold,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSales ASC
LIMIT 10;
```

### 2. Výkonnosť podľa regiónov

Analyzovaním predaja podľa geografických oblastí sme získali prehľad o regionálnych výkonnostiach produktov. Porovnaním výkonu v rôznych krajinách alebo oblastiach môžeme lepšie pochopiť, kde sú konkrétne produkty najúspešnejšie.

* Identifikáciou týchto regionálnych rozdielov môžeme prispôsobiť ponuku a marketingové kampane pre rôzne trhy, čo vedie k efektívnejšiemu prístupu k zákazníkom.

![vykonostregionov](https://github.com/user-attachments/assets/a8d01afd-e2e0-4ccd-9634-2ce9375da516)

*Graf výkonnosť podľa regiónov*

```sql
SELECT 
    c.Country,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimCustomer c ON f.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY TotalSales DESC;
```

### 3. Analýza dodávateľov

Analyzáciou výkonnosti dodávateľov sme mohli porovnať, ktorý dodávateľ zabezpečuje najlepšie výsledky v oblasti dodávok tovaru.

* Zistenie najlepších a najhorších dodávateľov umožňuje spoločnosti optimalizovať vzťahy s dodávateľmi a zabezpečiť hladký prístup k potrebným produktom pri optimálnych nákladoch.
* Identifikácia nedostatočne výkonných dodávateľov je užitočná pri hľadaní alternatívnych riešení alebo zlepšení procesov dodávok.

Tieto analýzy poskytujú hlboký pohľad na výkonnosť predaja, produktov, regionálnych trhov a dodávateľských vzťahov, čo vedie k lepšiemu riadeniu podnikových procesov a zvyšovaniu efektivity a ziskovosti.

![analyzadodavatelov1](https://github.com/user-attachments/assets/5a6a03e2-88ff-43f4-89dc-8a7b13eae995)

*Graf najlepších dodávateľov*

```sql
SELECT 
    s.SupplierName,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalSales DESC
LIMIT 5;
```

![analyzadodavatelov2](https://github.com/user-attachments/assets/da9ac645-9c26-4c0e-8fac-2cec72441d69)

*Graf najhorších dodávateľov*

```sql
SELECT 
    s.SupplierName,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimProduct p ON f.ProductID = p.ProductID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.SupplierName
ORDER BY TotalSales ASC
LIMIT 5;
```

### 4. Trendy predaja v čase

Analyzovaním predaja na rôznych úrovniach, ako mesačne, štvrťročne alebo ročne, sme získali prehľad o vývoji predajov počas rôznych časových období. Identifikáciou sezónnych výkyvov sme mohli odhaliť obdobia s vyššou alebo nižšou predajnou aktivitou, čo nám umožňuje lepšie plánovanie a adaptáciu predajných stratégií.

* Mesačné a ročné trendy poskytujú detailný pohľad na sezónne výkyvy, ktoré môžu ovplyvniť dopyt po produktoch.
* Výsledky nám umožňujú lepšie pochopiť, ktoré mesiace či obdobia sú najvýznamnejšie z hľadiska predaja, a vďaka tomu optimalizovať marketingové aktivity a zásoby.

![trendy1](https://github.com/user-attachments/assets/59780760-4f32-4e6c-93d6-618767cdbadd)

*Graf trendov za mesiac*

```sql
SELECT 
    d.Month,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month
LIMIT 10;
```

![trendy2](https://github.com/user-attachments/assets/7c767772-379b-48b0-9ec1-03ba66a506a0)

*Graf trendov za rok*

```sql
SELECT 
    d.Month,
    SUM(f.TotalSales) AS TotalSales
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month;
```

### 5. Analýza objednávok

Analyzovali sme priemernú hodnotu objednávok a sledovali trend v počte objednávok, čo nám poskytuje informácie o celkovom dopyte a efektívnosti procesov predaja.

* Priemerná hodnota objednávok nám pomáha pochopiť, akú hodnotu majú priemerné objednávky a umožňuje nám zlepšovať cenovú stratégiu alebo optimalizovať zľavy.
* Trend počtu objednávok poskytuje informácie o sezónnych výkyvoch a potenciálnych skokoch v dopyte, čo umožňuje lepšie plánovanie kapacít a zdrojov.

![analyzaobjednavok1](https://github.com/user-attachments/assets/fe38eed9-931d-4eeb-a67f-377532a67985)

*Graf priemernej hodnoty objednávok*

```sql
SELECT 
    f.OrderID,
    SUM(f.TotalSales) AS OrderValue
FROM FactSales f
GROUP BY f.OrderID;

SELECT AVG(OrderValue) AS AverageOrderValue
FROM (
    SELECT 
        f.OrderID,
        SUM(f.TotalSales) AS OrderValue
    FROM FactSales f
    GROUP BY f.OrderID
) subquery;
```

![analyzaobjednavok2](https://github.com/user-attachments/assets/9ec67207-6e40-4a95-9772-f953d1d82c4d)

*Graf trendov v počte objednávok*

```sql
SELECT 
    d.Month,
    COUNT(DISTINCT f.OrderID) AS TotalOrders
FROM FactSales f
JOIN DimDate d ON f.Date = d.Date
GROUP BY d.Month
ORDER BY d.Month
LIMIT 10;
```

---

# Záver

V rámci analýzy Northwind Dataset sme vytvorili efektívny ETL proces, ktorý umožňuje extrahovať, transformovať a načítať údaje na účely detailnej obchodnej analýzy. Výsledky jednotlivých analýz – predajné trendy, výkonnosť produktov, geografické výkonnosti, analýza objednávok a výkonnosť dodávateľov – poskytujú cenné informácie na optimalizáciu obchodných procesov, marketingových stratégií a vzťahov s dodávateľmi.

Použité dimenzionálne a faktové tabuľky ako DimDate, DimProduct, DimCustomer a FactSales umožňujú robustnú analýzu naprieč rôznymi časovými a geografickými aspektmi. Analytické SQL dotazy prispievajú k hlbšiemu pochopeniu obchodných procesov a odhaľujú kľúčové trendy a príležitosti na zlepšenie.

Výsledky týchto analýz môžu byť využité na efektívnejšie plánovanie, predikciu dopytu, zlepšenie zákazníckej spokojnosti a zvýšenie ziskovosti spoločnosti.

---

Autor: **Tomáš Zeleňák**
