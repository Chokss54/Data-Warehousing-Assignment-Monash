/*
*   SQL Implementation for the Level 0 Star Schema / MonEquipe Data Warehouse
*/


/*
*   DROP TABLE Statments for running the full script
*/
DROP TABLE Sales_Dim_V2;
DROP TABLE Hire_Dim_V2;
DROP TABLE Customer_Dim_V2;
DROP TABLE CustomerType_Dim_V2;
DROP TABLE Staff_Dim_V2;
DROP TABLE Equipment_Dim_V2;
DROP TABLE Category_Dim_V2;
DROP TABLE Hire_Fact_V2;
DROP TABLE Sales_Fact_V2;


/*
*   Creating the DIMENSION tables
*   Dimensions: Sales, Hire, Customer, CustomerType, Staff, Equipment, Category
*/
CREATE TABLE Sales_Dim_V2 AS 
SELECT 
    sales_id, 
    sales_date, 
    unit_sales_price 
FROM sales;

CREATE TABLE Hire_Dim_V2 AS
SELECT 
    hire_id, 
    start_date, 
    end_date, 
    unit_hire_price
FROM hire;

CREATE TABLE Customer_Dim_V2 AS 
SELECT 
    customer_id,
    customer_type_id,
    name,
    gender,
    phone,
    email
FROM customer;

CREATE TABLE CustomerType_Dim_V2 AS
SELECT *
FROM customer_type;

CREATE TABLE Staff_Dim_V2 AS
SELECT *
FROM staff;

CREATE TABLE Equipment_Dim_V2 AS
SELECT *
FROM equipment;

CREATE TABLE Category_Dim_V2 AS
SELECT *
FROM category;


/*
*   Creating the SALES FACT table - Sales_Fact_V1
*/
CREATE TABLE Sales_Fact_V2 AS
SELECT
    S.sales_id,
    S.equipment_id,
    S.customer_id,
    S.staff_id,  
    SUM(S.quantity) AS number_of_equipment_sold,
    SUM(S.total_sales_price) AS total_sales_revenue,
    COUNT(S.sales_id) AS number_of_sales  -- Should be 1 for all rows
FROM
    sales S
GROUP BY
    S.sales_id,
    S.equipment_id,
    S.customer_id,
    S.staff_id;


/*
*   Creating the HIRE FACT table - Hire_Fact_V2
*/
CREATE TABLE Hire_Fact_V2 AS
SELECT
    H.hire_id,
    H.equipment_id,
    H.Customer_id,
    H.Staff_id,
    SUM(H.quantity) AS number_of_equipment_hired,
    SUM(H.total_hire_price) AS total_hiring_revenue,
    COUNT(H.hire_id) AS number_of_hires  -- Should be 1 for all rows
FROM
    hire H
GROUP BY
    H.hire_id,
    H.equipment_id,
    H.Customer_id,
    H.Staff_id;

COMMIT;
