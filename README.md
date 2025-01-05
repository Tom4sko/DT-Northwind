# ETL Proces pre Northwind Dataset

Northwind Dataset predstavuje vzorovú databázu, ktorá obsahuje údaje o predaji, produktoch, zákazníkoch, dodávateľoch a ďalších aspektoch obchodných operácií. Táto dokumentácia sa zameriava na analýzu rôznych trendov a výkonov na základe údajov extrahovaných z Northwind Dataset. Cieľom je identifikovať kľúčové poznatky o predaji, výkonnosti produktov, geografických trendoch a dodávateľoch, ktoré môžu pomôcť v optimalizácii obchodných procesov.

---

## Obsah

- [Nastavenie základnej databázy](#nastavenia-zakladnej-databazy)
- [Dimenzionálne a faktové tabuľky](#dimenzionalne-a-faktove-tabulky)
- [Výkonnosť produktov](#vykonnost-produktov)
- [Výkonnosť podľa regiónov](#vykonnost-podla-regionov)
- [Analýza dodávateľov](#analyza-dodavatelov)
- [Trendy predaja v čase](#trendy-predaja-v-case)
- [Analýza objednávok](#analyza-objednavok)
- [Záver](#zaver)


---

# ERD Diagram

ERD (Entity-Relationship Diagram) znázorňuje hlavné entity, ich atribúty a vzťahy v databáze pre dataset Northwind. Nižšie nájdete podrobný popis kľúčových entít a ich vzťahov:

### Orders (Objednávky):
* Táto tabuľka obsahuje údaje o objednávkach, ako sú OrderDate (dátum objednávky), CustomerID (ID zákazníka), EmployeeID (ID zamestnanca) a ShipperID (ID prepravcu).
* Je prepojená s tabuľkou Order Details na určenie produktov zahrnutých v jednotlivých objednávkach.

### Order Details (Podrobnosti objednávok):
* Táto tabuľka ukladá detaily o objednávkach, vrátane ProductID (ID produktu), OrderID (ID objednávky), Quantity (množstvo) a Price (cena).
* Je prepojená s tabuľkami Orders a Products, čím spája informácie medzi konkrétnymi objednávkami a produktmi, ktoré obsahujú.

### Products (Produkty):

* Obsahuje údaje o produktoch, ako sú ProductName (názov produktu), SupplierID (ID dodávateľa), CategoryID (ID kategórie), Unit (jednotka) a Price (cena).
* Je prepojená s tabuľkami Categories a Suppliers na podrobné zatriedenie produktov a informácie o ich dodávateľoch.

### Customers (Zákazníci):

* Táto tabuľka obsahuje údaje o zákazníkoch, vrátane CustomerName (meno zákazníka), ContactName (kontaktné meno), Address (adresa), City (mesto), Country (krajina) a ďalšie geografické detaily.
* Je prepojená s tabuľkou Orders, aby identifikovala, ktorý zákazník vykonal konkrétnu objednávku.

### Suppliers (Dodávatelia):

* Obsahuje informácie o dodávateľoch, ako sú SupplierName (názov dodávateľa), ContactName (kontaktné meno), City (mesto), Country (krajina) a Phone (telefón).
* Je prepojená s tabuľkou Products na určenie, ktorý dodávateľ poskytuje konkrétne produkty.

### Categories (Kategórie):

* Predstavuje kategórie produktov s atribútmi, ako sú CategoryName (názov kategórie) a Description (popis).
* Je prepojená s tabuľkou Products, aby zatriedila produkty do relevantných kategórií.

### Shippers (Prepravcovia):

* Obsahuje údaje o prepravných spoločnostiach, ako sú ShipperName (názov prepravcu) a Phone (telefón).
 * Je prepojená s tabuľkou Orders, aby sa zaznamenalo, ktorá spoločnosť zabezpečuje doručenie konkrétnej objednávky.

### Employees (Zamestnanci):

* Obsahuje údaje o zamestnancoch, vrátane FirstName (krstné meno), LastName (priezvisko), BirthDate (dátum narodenia) a Notes (poznámky).
* Je prepojená s tabuľkou Orders, aby sa identifikovalo, ktorý zamestnanec spracoval objednávku.

![Northwind_ERD](https://github.com/user-attachments/assets/ffd2d153-9a0e-498c-abd2-93b55f456b4b)

# Dimenzionálne a faktové tabuľky
### DimDate
Táto tabuľka obsahuje dátové dimenzie na základe dátumu objednávky, ktoré umožňujú analýzu predajov podľa dní, mesiacov, štvrťrokov, rokov a ďalších časových jednotiek.

![DIM](https://github.com/user-attachments/assets/6cfd58ea-4404-456c-80f5-8c5ac6e4b69c)

```sql
CREATE OR REPLACE TABLE DimDate AS
SELECT 
    DISTINCT 
    DATE_TRUNC('day', o.OrderDate) AS Date,
    DATE_TRUNC('month', o.OrderDate) AS Month,
    DATE_TRUNC('year', o.OrderDate) AS Year,
    EXTRACT(month FROM o.OrderDate) AS MonthNumber,
    EXTRACT(quarter FROM o.OrderDate) AS Quarter,
    EXTRACT(week FROM o.OrderDate) AS WeekNumber,
    EXTRACT(day FROM o.OrderDate) AS DayNumber
FROM Orders o;
```

### DimProduct
Obsahuje informácie o produktoch, kategóriách a dodávateľoch.

```sql
CREATE OR REPLACE TABLE DimProduct AS
SELECT DISTINCT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    c.CategoryName,
    p.SupplierID,
    s.SupplierName
FROM Products p
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID;
```

### DimCustomer
Tabuľka pre údaje o zákazníkoch, ich polohe a ďalších atribútoch.

```sql
CREATE OR REPLACE TABLE DimCustomer AS
SELECT DISTINCT 
    c.CustomerID,
    c.CustomerName,
    c.Country,
    c.City,
    c.PostalCode
FROM Customers c;
```

### FactSales
```sql
CREATE OR REPLACE TABLE FactSales AS
SELECT 
    o.OrderID,
    DATE_TRUNC('day', o.OrderDate) AS Date,
    od.ProductID,
    p.CategoryID,
    p.SupplierID,
    c.CustomerID,
    od.Quantity,
    (od.Quantity * p.Price) AS TotalSales
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Customers c ON o.CustomerID = c.CustomerID;
```

# Nastavenie základnej databázy

Pre účely tejto analýzy bola vytvorená databáza s názvom PEACOCK_NORTHWIND_DB so štruktúrou schémy a tabuliek pre staging a analytické dáta.

```sql
CREATE DATABASE PEACOCK_NORTHWIND_DB;
USE PEACOCK_NORTHWIND_DB;
CREATE SCHEMA PEACOCK_NORTHWIND_DB.staging;
USE SCHEMA PEACOCK_NORTHWIND_DB.staging;
```

---

# Ciele práce

### 1. Výkonnosť produktov

Analyzovali sme najpredávanejšie produkty a produkty s nižším predajom, aby sme pochopili, ktoré položky generujú najväčší objem predaja a ktoré potrebujú zlepšenia. Na základe týchto údajov môžeme implementovať potrebné úpravy produktového portfólia a marketingových stratégií.

* Najpredávanejšie produkty nám poskytujú prehľad o najpopulárnejších produktoch, ktoré najviac prispievajú k tržbám.
* Produkty s nižším predajom môžu byť predmetom ďalšej analýzy, kde navrhneme opatrenia na zlepšenie predaja, napríklad zlepšením ich viditeľnosti alebo úpravou cenovej politiky.
  
![vykonostproduktov1](https://github.com/user-attachments/assets/1c53b3ba-b010-492d-a16d-32090d685445)
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
