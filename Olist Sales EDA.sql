-- rename order_status values of orders that are not paid yet to 'Unpaid'
UPDATE olist..orders
SET order_status = 'Unpaid'
WHERE order_status IN ('approved','invoiced', 'created', 'unavailable','cancelled')
-- rename order_status values of orders that are already paid to 'Paid'
UPDATE olist..orders
SET order_status = 'Paid'
WHERE order_status != 'Unpaid'
-- Which state contributes the highest percentage of total sales through customer transactions?
	-- show data of paid purchases
SELECT c.customer_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON o.order_id=i.order_id
WHERE order_status='Paid'
	-- create a pivot table to show the sum value of the sales number by different years
SELECT * FROM 
(SELECT c.customer_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table
	-- an extra row was also created to show the grand total value
WITH pivot_table AS( 
SELECT * FROM 
(SELECT c.customer_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(
SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table)
SELECT COALESCE(customer_state,'Grand Total') AS customer_state,
		SUM ("2016") AS sales_2016,
		SUM("2017") AS sales_2017,
		SUM("2018") AS sales_2018
FROM pivot_table
GROUP BY ROLLUP (customer_state)
	-- calculate percentage of revenue coming from customers from different states, 
	-- there are some rows in 2016 with null values, which can be understood that there were no customers coming from that state in 2016, so the null value was replaced with 0
WITH pivot_table AS( 
SELECT * FROM 
(SELECT c.customer_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(
SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table),
sales_table AS (
SELECT COALESCE(customer_state,'Grand Total') AS customer_state,
		SUM ("2016") AS sales_2016,
		SUM ("2017") AS sales_2017,
		SUM("2018") AS sales_2018
FROM pivot_table
GROUP BY ROLLUP (customer_state)
) 
SELECT customer_state,
		ISNULL(sales_2016,0) AS sales_2016,
		ISNULL(sales_2016,0)/(SELECT sales_2016 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2016,
		sales_2017,
		sales_2017/(SELECT sales_2017 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2017,
		sales_2018,
		sales_2018/(SELECT sales_2018 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2018
FROM sales_table
-- CREATE VIEW
CREATE VIEW revenue_pct_by_customers_states AS
WITH pivot_table AS( 
SELECT * FROM 
(SELECT c.customer_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(
SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table),
sales_table AS (
SELECT COALESCE(customer_state,'Grand Total') AS customer_state,
		SUM ("2016") AS sales_2016,
		SUM ("2017") AS sales_2017,
		SUM("2018") AS sales_2018
FROM pivot_table
GROUP BY ROLLUP (customer_state)
) 
SELECT customer_state,
		ISNULL(sales_2016,0) AS sales_2016,
		ISNULL(sales_2016,0)/(SELECT sales_2016 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2016,
		sales_2017,
		sales_2017/(SELECT sales_2017 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2017,
		sales_2018,
		sales_2018/(SELECT sales_2018 FROM sales_table WHERE customer_state = 'Grand Total')*100 AS percentage_2018
FROM sales_table
-- What is the ranking of each state in terms of sellers' earned sales?
	-- create a pivot table showing sales number of each state's sellers in 2016, 2017 and 2018
SELECT * FROM 
(SELECT s.seller_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..sellers AS s
JOIN olist..order_items AS i
ON s.seller_id=i.seller_id
JOIN olist..orders AS o
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table
	-- there are some rows with null value, which can be understood as there are no sellers from that state during the mentioned year, so I replaced the null value with 0
WITH pivot_table AS 
(SELECT * FROM 
(SELECT s.seller_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..sellers AS s
JOIN olist..order_items AS i
ON s.seller_id=i.seller_id
JOIN olist..orders AS o
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table)
SELECT seller_state,
		ISNULL("2016",0) AS sales_2016,
		ISNULL("2017",0) AS sales_2017,
		ISNULL ("2018",0) AS sales_2018
FROM pivot_table
	-- give ranks to states
WITH pivot_table AS 
(SELECT * FROM 
(SELECT s.seller_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..sellers AS s
JOIN olist..order_items AS i
ON s.seller_id=i.seller_id
JOIN olist..orders AS o
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table),
sales_table AS (
SELECT seller_state,
		ISNULL("2016",0) AS sales_2016,
		ISNULL("2017",0) AS sales_2017,
		ISNULL ("2018",0) AS sales_2018
FROM pivot_table)
SELECT seller_state,
		sales_2016,
		RANK() OVER (ORDER BY sales_2016 DESC) AS rank_2016,
		sales_2017,
		RANK() OVER (ORDER BY sales_2017 DESC) AS rank_2017,
		sales_2018,
		RANK() OVER (ORDER BY sales_2018 DESC) AS rank_2018
FROM sales_table
ORDER BY rank_2017, rank_2016, rank_2018 -- I used the rank in 2017 as the benchmark to see how different the sellers' performances were in 3 years
-- CREATE VIEW
CREATE VIEW revenue_ranks_by_sellers_states AS
WITH pivot_table AS 
(SELECT * FROM 
(SELECT s.seller_state, 
		i.price, 
		YEAR(order_purchase_timestamp) AS order_year
FROM olist..sellers AS s
JOIN olist..order_items AS i
ON s.seller_id=i.seller_id
JOIN olist..orders AS o
ON o.order_id=i.order_id
WHERE order_status='Paid') AS order_price
PIVOT
(SUM(price)
FOR order_year IN ([2016],[2017],[2018])
) AS pivot_table),
sales_table AS (
SELECT seller_state,
		ISNULL("2016",0) AS sales_2016,
		ISNULL("2017",0) AS sales_2017,
		ISNULL ("2018",0) AS sales_2018
FROM pivot_table)
SELECT seller_state,
		sales_2016,
		RANK() OVER (ORDER BY sales_2016 DESC) AS rank_2016,
		sales_2017,
		RANK() OVER (ORDER BY sales_2017 DESC) AS rank_2017,
		sales_2018,
		RANK() OVER (ORDER BY sales_2018 DESC) AS rank_2018
FROM sales_table
-- What is the percentage of customers ordering from sellers from the same state and from another state?
	-- look at all orders with customer's state and seller's state
SELECT i.order_id,
		c.customer_state,
		s.seller_state,
		YEAR(o.order_purchase_timestamp) AS year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON i.order_id=o.order_id
JOIN olist..sellers AS s
ON i.seller_id=s.seller_id
	-- count the number of orders coming from customers who live in the same states with sellers
WITH order_table AS
(SELECT i.order_id,
		c.customer_state,
		s.seller_state,
		YEAR(o.order_purchase_timestamp) AS year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON i.order_id=o.order_id
JOIN olist..sellers AS s
ON i.seller_id=s.seller_id)
SELECT year,
		COUNT(order_id) AS same_state
FROM order_table
WHERE customer_state=seller_state
GROUP BY year
	-- calculate the percentage of customers ordering from sellers from another state and sellers from the same state
WITH order_table AS
(SELECT i.order_id,
		c.customer_state,
		s.seller_state,
		YEAR(o.order_purchase_timestamp) AS year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON i.order_id=o.order_id
JOIN olist..sellers AS s
ON i.seller_id=s.seller_id),
sub_table AS (
SELECT year,
		COUNT(order_id) AS same_state
FROM order_table
WHERE customer_state=seller_state
GROUP BY year)
SELECT year,
		same_state/CAST((SELECT COUNT(order_id) FROM order_table AS o WHERE o.year=s.year GROUP BY year) AS decimal(10,2))*100 AS same_state_pct,
		100-(same_state/CAST((SELECT COUNT(order_id) FROM order_table AS o WHERE o.year=s.year GROUP BY year) AS decimal(10,2))*100) AS other_state_pct
FROM sub_table AS s

-- CREATE VIEW
CREATE VIEW same_state_vs_other_state AS
WITH order_table AS
(SELECT i.order_id,
		c.customer_state,
		s.seller_state,
		YEAR(o.order_purchase_timestamp) AS year
FROM olist..customers AS c
JOIN olist..orders AS o
ON c.customer_id=o.customer_id
JOIN olist..order_items AS i
ON i.order_id=o.order_id
JOIN olist..sellers AS s
ON i.seller_id=s.seller_id),
sub_table AS (
SELECT year,
		COUNT(order_id) AS same_state
FROM order_table
WHERE customer_state=seller_state
GROUP BY year)
SELECT year,
		same_state/CAST((SELECT COUNT(order_id) FROM order_table AS o WHERE o.year=s.year GROUP BY year) AS decimal(10,2))*100 AS same_state_pct,
		100-(same_state/CAST((SELECT COUNT(order_id) FROM order_table AS o WHERE o.year=s.year GROUP BY year) AS decimal(10,2))*100) AS other_state_pct
FROM sub_table AS s


