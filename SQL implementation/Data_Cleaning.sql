/*
*   DATA CLEANING PREPERATION
*   ----------------------------------
*   Data Cleaning will be done on a COPY of the Monequip Operational Database.
*   This is in order to:
*   - Preserve Integegrity of the the monequip Operational DB
*   - Easily restart data cleaning in case of mistakes.
*/

-- DROP TABLE queries for restarting the DATA Cleaning Script
DROP TABLE address;
DROP TABLE customer;
DROP TABLE customer_type;
DROP TABLE category;
DROP TABLE equipment;
DROP TABLE sales;
DROP TABLE hire;
DROP TABLE staff;

-- COPY of Monequip Operational DB for performing Data Cleaning
CREATE TABLE address AS SELECT * FROM monequip.address;
CREATE TABLE customer AS SELECT * FROM monequip.customer;
CREATE TABLE customer_type AS SELECT * FROM monequip.customer_type;
CREATE TABLE category AS SELECT * FROM monequip.category;
CREATE TABLE equipment AS SELECT * FROM monequip.equipment;
CREATE TABLE sales AS SELECT * FROM monequip.sales;
CREATE TABLE hire AS SELECT * FROM monequip.hire;
CREATE TABLE staff AS SELECT * FROM monequip.staff;

/*
*   DATA CLEANING CHECKS:
*   ----------------------------------
*   1. Duplication Problems
*       a) Duplication Between Records
*       b) Duplication Between Attributes
*       c) Duplication Between Tables
*   2. Relationship Problems
*   3. Inconsistent Values
*       a) At Record Level
*       b) Between Attributes
*   4. Incorrect Values
*       a) At Attribute Level
*       b) Between Records
*       c) Between Tables
*   5. Null Value Problems
*       a) At Attribute Level
*       b) Between Records
*       c) Between Attributes
*/


/*
*   1. DUPLICATION PROBLEMS 
*   2. RELATIONSHIP PROBELEMS
*/

-- Duplicate problem
-- Checking duplicate records by counting the unique id of the table

-- Equipment
--To check duplicate records
SELECT equipment_id, COUNT(*)
FROM equipment
GROUP BY equipment_id
HAVING COUNT(*) > 1;

-- Address
--To check duplicate records
SELECT address_id, COUNT(*)
FROM address
GROUP BY address_id
HAVING COUNT(*) > 1;

-- Hire
--To check duplicate records
SELECT hire_id, COUNT(*)
FROM hire
GROUP BY hire_id
HAVING COUNT(*) > 1;

-- CustomerType
--To check duplicate records
SELECT customer_type_id, COUNT(*)
FROM customer_type
GROUP BY customer_type_id
HAVING COUNT(*) > 1;

-- Staff
--To check duplicate records
SELECT staff_id, COUNT(*)
FROM staff
GROUP BY staff_id
HAVING COUNT(*) > 1;

-- Category
--To check duplicate records
SELECT category_id, COUNT(*)
FROM category
GROUP BY category_id
HAVING COUNT(*) > 1;

-- Sales
--To check duplicate records
SELECT sales_id, COUNT(*)
FROM sales
GROUP BY sales_id
HAVING COUNT(*) > 1;

-- Customer
--To check duplicate records
SELECT customer_id, COUNT(*)
FROM customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Duplicated records found (customer_id 52 has 4 records in the customer table)
-- To clear duplicate records by recreating customer table selecting distict
drop table customer;

CREATE TABLE customer AS
SELECT DISTINCT *
FROM monequip.customer;

-- Now no more duplicates in customer_clean table
SELECT customer_id, COUNT(*)
FROM customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Relationship and constraint violations
-- Checking if FK from a table can be found as PK in its corresponding tables

-- Equipment
-- To check invalid FK values
SELECT *
FROM equipment
WHERE category_id NOT IN
(SELECT category_id
FROM equipment);

-- Sales
SELECT *
FROM sales
WHERE customer_id NOT IN
(SELECT customer_id
FROM customer);

SELECT *
FROM sales
WHERE equipment_id NOT IN
(SELECT equipment_id
FROM equipment);

SELECT *
FROM sales
WHERE staff_id NOT IN
(SELECT staff_id
FROM staff);

-- Customer
SELECT *
FROM customer
WHERE customer_type_id NOT IN
(SELECT customer_type_id
FROM customer_type);

SELECT *
FROM customer
WHERE address_id NOT IN
(SELECT address_id
FROM address);

-- Hire
-- Relationship problem found here (customer_id 181 from hire_id 301 not found in customer table)
SELECT *
FROM hire
WHERE customer_id NOT IN
(SELECT customer_id
FROM customer);

-- ce (equipment_id 190 from hire_id 301 not found in equipment table)
SELECT *
FROM hire
WHERE equipment_id NOT IN
(SELECT equipment_id
FROM equipment);

-- Relationship problem found here (301,302,303,304 staff_id (FK) from hire not found in staff table)
SELECT *
FROM hire
WHERE staff_id NOT IN
(SELECT staff_id
FROM staff);

--To resolve this issue we set the FK to null
update hire
set customer_id = null
where customer_id not in (select customer_id from customer);

update hire
set equipment_id = null
where equipment_id not in (select equipment_id from equipment);

update hire
set staff_id = null
where staff_id not in (select staff_id from staff);

-- recheck if relationship problem still persist
SELECT *
FROM hire
WHERE customer_id NOT IN
(SELECT customer_id
FROM customer);

SELECT *
FROM hire
WHERE equipment_id NOT IN
(SELECT equipment_id
FROM equipment);

SELECT *
FROM hire
WHERE staff_id NOT IN
(SELECT staff_id
FROM staff);



/*
*   3. INCONSISTENT VALUES 
*       a) Different Precision
*       b) Conflicting Attributes
*       c) Different Values
*/

-- CONFLICTING ATTRIBUTES: Conflicting Start and End Dates for Hires
SELECT * 
FROM hire 
WHERE start_date > end_date;

-- Errors & Solutions:
DELETE 
FROM hire 
WHERE start_date > end_date;


-- DIFFERENT VALUES: Inconsistent branch names
SELECT company_branch, COUNT(company_branch)
FROM staff
GROUP BY company_branch
ORDER BY company_branch ASC;


-- DIFFERENT VALUES: Inconsistent Suburb Names
SELECT suburb, COUNT(suburb)
FROM address
GROUP BY suburb
ORDER BY suburb ASC;


-- DIFFERENT VALUES: Inconsistant Street Names
SELECT street_name, COUNT(street_name)
FROM address
GROUP BY street_name
ORDER BY street_name ASC;

-- Error: 'Oakdean Blvd' & 'Oakdean Boulevard'
UPDATE address
SET street_name = 'Oakdean Boulevard'
WHERE street_name = 'Oakdean Blvd';

-- Error: '& 2/3 Jersey Court'
SELECT * FROM address ORDER BY street_name ASC;
UPDATE address
SET street_name = 'Jersey Court'
WHERE address_id = 54;

-- DIFFERENT VALUES: Inconsistant Manufacturer Names
SELECT manufacturer, COUNT(manufacturer)
FROM equipment
GROUP BY manufacturer
ORDER BY manufacturer ASC;

-- Error: 'hitachi' and 'HITACHI'
UPDATE equipment
SET manufacturer = INITCAP(manufacturer)
WHERE manufacturer = 'HITACHI';

/* 
*   4. INCORRECT VALUES
*       a) Incorrect Range
*       b) Wrong Value
*/

-- INCORRECT RANGE: Negative values in the Sales table
SELECT * 
FROM sales 
WHERE quantity <= 0 or unit_sales_price <= 0 or total_sales_price <= 0;

-- Error: sales_id = 151, quantity = -3
DELETE 
FROM sales
WHERE 
    quantity <= 0 
    OR unit_sales_price <= 0 
    OR total_sales_price <= 0;


-- INCORRECT RANGE: Negative values in the Hire table
SELECT *
FROM hire
WHERE 
    quantity <= 0 
    OR unit_hire_price <= 0 
    OR total_hire_price <= 0;

-- Errors: Hire_ID = 303, 304 -> Total Hire Price = -150, -1
DELETE
FROM hire
WHERE 
    quantity <= 0 
    OR unit_hire_price <= 0 
    OR total_hire_price <= 0;


-- INCORRECT RANGE: Sales Dates Out of Range (not between apr 2018 and dec 2020)
SELECT *
FROM sales
WHERE 
    sales_date < TO_DATE('1-4-2018','DD-MM-YYYY') 
    OR sales_date > TO_DATE('31-12-2020', 'DD-MM-YYYY');

-- INCORRECT RANGE: Hire Dates Out of Range (not between apr 2018 and dec 2020)
SELECT *
FROM hire
WHERE 
    start_date < TO_DATE('1-4-2018','DD-MM-YYYY') 
    OR start_date > TO_DATE('31-12-2020', 'DD-MM-YYYY')
    OR end_date < TO_DATE('1-4-2018','DD-MM-YYYY')
    OR end_date > TO_DATE('31-12-2020', 'DD-MM-YYYY');


-- WRONG VALUE: Incorrectly Calculated Total Sales Price
SELECT *
FROM (
    SELECT 
        sales_id, 
        quantity, 
        unit_sales_price, 
        total_sales_price, 
        (unit_sales_price * quantity) AS recalc_total_price
    FROM sales
    )
WHERE recalc_total_price <> total_sales_price;

-- WRONG VALUE: Incorrectly Calculated Total Hire Price
SELECT * 
FROM hire
WHERE 
    start_date = end_date 
    AND total_hire_price <> (quantity * unit_hire_price / 2);

-- Error: Hire_ID = 301 -> total_hire_price is incorrect
/*
DELETE
FROM hire
WHERE 
    start_date = end_date 
    AND total_hire_price <> (quantity * unit_hire_price / 2);
*/

-- WRONG VALUE: Hire <> (end date - start date) * unit hire price * quantity
SELECT *
FROM hire
WHERE 
    start_date <> end_date
    AND total_hire_price <> ((end_date - start_date) * quantity * unit_hire_price);
-- Need to check as there are 166 rows with this Error


-- WRONG VALUE: Sales <> unit sales price * quantity
SELECT *
FROM sales
WHERE total_sales_price <> unit_sales_price * quantity;



/*    
*   5. NULL VALUE PROBLEMS
*       a) Null Attributes
*/

-- NULL ATTRIBUTES: Equipment with no category_id instead of the 'null' category
SELECT *
FROM equipment
WHERE category_id = null;


COMMIT;
