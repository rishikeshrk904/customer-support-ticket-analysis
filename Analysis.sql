-- =====================================================
-- PROJECT: CUSTOMER SUPPORT ANALYSIS
-- FILE: analysis.sql
-- DESCRIPTION: Data validation, cleaning checks, and analysis queries
-- =====================================================


-- =====================================================
-- 1. DATA VALIDATION / INITIAL CHECKS
-- =====================================================

-- Check total rows in each tables

select count(*) from customer
select count(*) from ticket
select count(*) from channel
select count(*) from product

-- Preview sample data

select * from customer limit 10
select * from ticket limit 10
select * from channel limit 5
select * from product limit 10

-- =====================================================
-- 2. NULL CHECKS
-- =====================================================

-- check null in customer table 
SELECT string_agg(
    format(
        'SELECT %L AS column_name,
                COUNT(*) AS null_count
         FROM public.%I
         WHERE %I IS NULL
         HAVING COUNT(*) > 0',
        column_name,
        table_name,
        column_name
    ),
    ' UNION ALL '
) AS query_to_run
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'customer';

-- Check null for tickets
SELECT string_agg(
    format(
        'SELECT %L AS column_name,
                COUNT(*) AS null_count
         FROM public.%I
         WHERE %I IS NULL
         HAVING COUNT(*) > 0',
        column_name,
        table_name,
        column_name
    ),
    ' UNION ALL '
) AS query_to_run
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'ticket';

-- =====================================================
-- 5. BASIC ANALYSIS (incomplete)
-- =====================================================

-- Total tickets
SELECT COUNT(*) AS total_tickets
FROM ticket;

-- Total customers
SELECT COUNT(*) AS total_customers
FROM customer;

-- Total products
SELECT COUNT(*) AS total_products
FROM product;

-- Tickets count by status
SELECT s.status_name, COUNT(*) AS total_tickets
FROM ticket t
JOIN status s ON s.status_id = t.t_status
GROUP BY s.status_name
ORDER BY total_tickets DESC;

-- Tickets count by Priority
SELECT p.priority_name, COUNT(*) AS total_tickets
FROM ticket t
JOIN priority p ON p.priority_id = t.t_priority
GROUP BY p.priority_name
ORDER BY total_tickets DESC;

-- Tickets count by Channel
SELECT c.channel_name, COUNT(*) AS total_tickets
FROM ticket t
JOIN channel c ON t_channel = c.channel_id
GROUP BY c.channel_name
ORDER BY total_tickets DESC;

-- Tickets count by Product
SELECT p.product_name, COUNT(*) AS total_tickets
FROM ticket t
JOIN product p ON t.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_tickets DESC;

-- ======================================
-- TICKET MASTER ANALYSIS VIEW
-- ======================================

CREATE VIEW ticket_analysis AS
SELECT
    -- Ticket
    t.id AS ticket_id,

    -- Status & Priority
    s.status_name,
    pr.priority_name,

    -- Ticket Date & Time
    t.t_date AS ticket_date,
    TO_CHAR(t.t_time, 'HH24:MI') AS ticket_time,

    -- Customer
    c.cx_id AS customer_id,
    c.name AS customer_name,
    c.age AS customer_age,

    CASE
        WHEN c.age < 25 THEN '18-24'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_range,

    c.email,

    -- Product
    p.product_name,

    -- Channel
    ch.channel_name,

    -- Feedback
    f.resolution,
    f.csr,

    CASE
        WHEN f.csr >= 4 THEN 'Positive'
        WHEN f.csr = 3 THEN 'Neutral'
        WHEN f.csr <= 2 THEN 'Negative'
        ELSE 'No Feedback'
    END AS feedback_sentiment

FROM ticket t

JOIN customer c 
ON t.cx_id = c.cx_id

JOIN product p 
ON t.product_id = p.product_id

JOIN channel ch 
ON t.t_channel = ch.channel_id

JOIN status s
ON t.t_status = s.status_id

JOIN priority pr
ON t.t_priority = pr.priority_id

LEFT JOIN feedback f 
ON t.id = f.ticket_id;



--===================================

--Diagnostic Query 

--===================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(c.cx_id) AS customer_match,
    COUNT(p.product_id) AS product_match,
    COUNT(tt.t_type_id) AS type_match,
    COUNT(ts.t_sub_id) AS subject_match,
    COUNT(s.status_id) AS status_match,
    COUNT(pr.priority_id) AS priority_match,
    COUNT(ch.channel_id) AS channel_match,

    -- ❌ Missing counts (very important)
    COUNT(*) - COUNT(c.cx_id) AS customer_missing,
    COUNT(*) - COUNT(p.product_id) AS product_missing,
    COUNT(*) - COUNT(tt.t_type_id) AS type_missing,
    COUNT(*) - COUNT(ts.t_sub_id) AS subject_missing,
    COUNT(*) - COUNT(s.status_id) AS status_missing,
    COUNT(*) - COUNT(pr.priority_id) AS priority_missing,
    COUNT(*) - COUNT(ch.channel_id) AS channel_missing

FROM raw_support_data r

LEFT JOIN customer c 
ON TRIM(LOWER(r.customer_email)) = TRIM(LOWER(c.email))

LEFT JOIN product p 
ON TRIM(LOWER(r.product)) = TRIM(LOWER(p.product_name))

LEFT JOIN ticket_type tt 
ON TRIM(LOWER(r.ticket_type)) = TRIM(LOWER(tt.t_type_name))

LEFT JOIN ticket_subject ts 
ON TRIM(LOWER(r.ticket_subject)) = TRIM(LOWER(ts.t_sub_name))

LEFT JOIN status s 
ON TRIM(LOWER(r.status)) = TRIM(LOWER(s.status_name))

LEFT JOIN priority pr 
ON TRIM(LOWER(r.priority)) = TRIM(LOWER(pr.priority_name))

LEFT JOIN channel ch 
ON TRIM(LOWER(r.channel)) = TRIM(LOWER(ch.channel_name));