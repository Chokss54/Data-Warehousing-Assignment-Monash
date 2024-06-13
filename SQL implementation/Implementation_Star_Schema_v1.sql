/*
*   SQL Implementation for the Level 1 Star Schema / MonEquipe Data Warehouse
*/


/*
*   DROP TABLE Statments for running the full script
*/
DROP TABLE time_dim_v1;

DROP TABLE season_dim_v1;

DROP TABLE branch_dim_v1;

DROP TABLE category_dim_v1;

DROP TABLE customertype_dim_v1;

DROP TABLE pricescale_dim_v1;

DROP TABLE sales_fact_v1;

DROP TABLE hire_fact_v1;

DROP TABLE temp_fact;

DROP TABLE time_dim_temp;

-- create CustomerTypeDim
CREATE TABLE customertype_dim_v1
    AS
        SELECT
            *
        FROM
            customer_type;

SELECT
    *
FROM
    customertype_dim_v1;

-- create CategoryDim
CREATE TABLE category_dim_v1
    AS
        SELECT
            *
        FROM
            category;

SELECT
    *
FROM
    category_dim_v1;

-- create SeasonDim
CREATE TABLE season_dim_v1 (
    season_id          CHAR(6),
    season_description VARCHAR2(32)
);

INSERT INTO season_dim_v1 VALUES (
    'SUMMER',
    'December, January, February'
);

INSERT INTO season_dim_v1 VALUES (
    'AUTUMN',
    'March, April, May'
);

INSERT INTO season_dim_v1 VALUES (
    'WINTER',
    'June, July, August'
);

INSERT INTO season_dim_v1 VALUES (
    'SPRING',
    'September, October, November'
);

SELECT
    *
FROM
    season_dim_v1;

-- create BranchDim
CREATE TABLE branch_dim_v1
    AS
        SELECT
            company_branch AS branch_id
        FROM
            staff;

SELECT
    *
FROM
    branch_dim_v1;

-- create PriceScaleDim
CREATE TABLE pricescale_dim_v1 (
    scale_id          NUMBER(1),
    scale_description VARCHAR2(16)
);

INSERT INTO pricescale_dim_v1 VALUES (
    1,
    'low sales'
);

INSERT INTO pricescale_dim_v1 VALUES (
    2,
    'medium sales'
);

INSERT INTO pricescale_dim_v1 VALUES (
    3,
    'high sales'
);

SELECT
    *
FROM
    pricescale_dim_v1;

-- create TimeDim

CREATE TABLE time_dim_temp (
    date_combine DATE
);

INSERT INTO time_dim_temp ( date_combine )
    SELECT
        sales_date
    FROM
        sales;

INSERT INTO time_dim_temp ( date_combine )
    SELECT
        start_date
    FROM
        hire;

SELECT
    *
FROM
    time_dim_temp;

CREATE TABLE time_dim_v1 (
    time_id CHAR(6),
    month   VARCHAR2(10),
    year    NUMBER(4)
);

INSERT INTO time_dim_v1 (
    time_id,
    month,
    year
)
    SELECT DISTINCT
        TO_NUMBER(to_char(date_combine, 'YYYYMM')),
        to_char(date_combine, 'MONTH'),
        TO_NUMBER(to_char(date_combine, 'YYYY'))
    FROM
        time_dim_temp;

SELECT
    *
FROM
    time_dim_v1
ORDER BY
    time_id;

-- temp_fact
CREATE TABLE temp_fact
    AS
        SELECT
            s.sales_id,
            h.hire_id,
            cg.category_id,
            ct.customer_type_id,
            st.company_branch,
            s.unit_sales_price,
            TO_NUMBER(to_char(s.sales_date, 'YYYYMM')) AS time_id_sales,
            TO_NUMBER(to_char(h.start_date, 'YYYYMM')) AS time_id_hire,
            to_char(s.sales_date, 'MM')                AS month
        FROM
            category      cg,
            customer_type ct,
            staff         st,
            sales         s,
            equipment     e,
            customer      c,
            hire          h
        WHERE
                cg.category_id = e.category_id
            AND e.equipment_id = s.equipment_id
            AND ct.customer_type_id = c.customer_type_id
            AND c.customer_id = s.customer_id
            AND st.staff_id = s.staff_id;

ALTER TABLE temp_fact ADD (
    season_id CHAR(6)
);

UPDATE temp_fact
SET
    season_id = 'SUMMER'
WHERE
    month IN ( '12', '01', '02' );

UPDATE temp_fact
SET
    season_id = 'AUTUMN'
WHERE
    month IN ( '03', '04', '05' );

UPDATE temp_fact
SET
    season_id = 'WINTER'
WHERE
    month IN ( '06', '07', '08' );

UPDATE temp_fact
SET
    season_id = 'SPRING'
WHERE
    month IN ( '09', '10', '11' );

ALTER TABLE temp_fact ADD (
    scale_id NUMBER(1)
);

UPDATE temp_fact
SET
    scale_id = 1
WHERE
    unit_sales_price < 5000;

UPDATE temp_fact
SET
    scale_id = 2
WHERE
        unit_sales_price >= 5000
    AND unit_sales_price <= 10000;

UPDATE temp_fact
SET
    scale_id = 3
WHERE
    unit_sales_price > 10000;

SELECT
    *
FROM
    temp_fact;

-- sales_fact_V1
CREATE TABLE sales_fact_v1
    AS
        SELECT
            time_id_sales            AS time_id,
            season_id,
            scale_id,
            category_id,
            customer_type_id,
            company_branch           AS branch_id,
            COUNT(s.sales_id)        AS number_of_sales,
            SUM(s.quantity)          AS number_of_equipment_sales,
            SUM(s.total_sales_price) AS total_sales_revenue
        FROM
            temp_fact t,
            sales     s
        WHERE
            s.sales_id = t.sales_id
        GROUP BY
            time_id_sales,
            season_id,
            scale_id,
            category_id,
            customer_type_id,
            company_branch;

SELECT
    *
FROM
    sales_fact_v1;

-- hire_fact_V1
CREATE TABLE hire_fact_v1
    AS
        SELECT
            time_id_hire            AS time_id,
            season_id,
            category_id,
            customer_type_id,
            company_branch          AS branch_id,
            COUNT(h.hire_id)        AS number_of_hire,
            SUM(h.quantity)         AS number_of_equipment_hires,
            SUM(h.total_hire_price) AS total_hire_revenue
        FROM
            temp_fact t,
            hire      h
        WHERE
            t.hire_id = h.hire_id
        GROUP BY
            time_id_hire,
            season_id,
            category_id,
            customer_type_id,
            company_branch;

SELECT
    *
FROM
    hire_fact_v1;

COMMIT;