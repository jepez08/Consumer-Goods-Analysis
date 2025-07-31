
## PRODUCT OWNER TASK 6: Get 1. Top markets, 2. Top products 3. Top customers, by net sales for a given financial year.

#** Found the fiscal year User Defined Function was slowing down the query. The query will get bigger and bigger as we do more joins. We can remove the UDF by:
#** 1. Creating a table with fiscal year data from an excel file and joining it or; 2. Create a fiscal year column on fact_sales_monthly saving us from another join.
## 1. Get Pre Invoice Discount. Replaced get_fiscal_year UDF by generating a table with fiscal_year and joining it to optimize duration time.
SELECT s.date, s.product_code, s.customer_code,
p.product, p.variant, s.sold_quantity,
g.gross_price as gross_price_per_item,
ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
JOIN dim_date dt
ON dt.fiscal_year = get_fiscal_year(s.date)
JOIN fact_gross_price g
ON g.fiscal_year = get_fiscal_year(s.date) and
g.product_code = s.product_code
JOIN fact_pre_invoice_deductions pre
ON pre.fiscal_year = get_fiscal_year(s.date) and
pre.customer_code = s.customer_code
WHERE get_fiscal_year(s.date) = 2021;

## 2. We removed the join from the step above (dim_date) as we created fiscal year column on fact_sales_monthly. We added CTE to perform net_invoice_sales calc - not ideal when more columns are coming
WITH cte1 as (
SELECT s.date, s.product_code, s.customer_code,
p.product, p.variant, s.sold_quantity,
g.gross_price,
ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
JOIN fact_gross_price g
ON g.fiscal_year = s.fiscal_year and
g.product_code = s.product_code
JOIN fact_pre_invoice_deductions pre
ON pre.fiscal_year = s.fiscal_year and
pre.customer_code = s.customer_code
WHERE s.fiscal_year = 2021)
SELECT *, gross_price_total - gross_price_total*pre_invoice_discount_pct as net_invoice_sales
FROM cte1;

## Therefore, we created a Database View copied below called sales_preinv_discount. Removed fiscal_year WHERE condition to make it general.
## Added join with dim_customer to get market as it was required by manager.
SELECT s.date, s.product_code, s.customer_code,
c.market,
p.product, p.variant, s.sold_quantity,
c.market,
g.gross_price,
ROUND(g.gross_price*s.sold_quantity,2) as gross_price_total,
pre.pre_invoice_discount_pct
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price g
ON g.fiscal_year = s.fiscal_year and
g.product_code = s.product_code
JOIN fact_pre_invoice_deductions pre
ON pre.fiscal_year = s.fiscal_year and
pre.customer_code = s.customer_code;

## Got net invoice sales through the calculation using FROM table View sales_preinv_discount.
SELECT *, (1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales,
(po.discounts_pct + other_deductions_pct) as post_invoice_discount_pct
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
ON po.date = s.date and
po.product_code = s.product_code and
po.customer_code = s.customer_code;

## Got post invoice discount pct by joining sales_preinv_discount View with fact_post_invoice_deductions table.
## This became sales_postinv_discount View.
SELECT s.date, s.fiscal_year, s.customer_code, s.market,
s.product_code, s.product, s.variant, s.sold_quantity,
s.gross_price_total, s.pre_invoice_discount_pct, 
(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales,
(po.discounts_pct + other_deductions_pct) as post_invoice_discount_pct
FROM sales_preinv_discount s
JOIN fact_post_invoice_deductions po
ON po.date = s.date and
po.product_code = s.product_code and
po.customer_code = s.customer_code;

## Got net_sales view by performing the calculation from sales_postinv_discount View.
## This became net_sales View.
SELECT *,
(1-post_invoice_discount_pct)*net_invoice_sales as net_sales
FROM gdb0041.sales_postinv_discount;


## Top Markets (1st item of the task) and created stored procedure for it.
SELECT market, ROUND(SUM(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales
WHERE fiscal_year=2021
GROUP BY market
ORDER BY net_sales_mln desc;

## Top Customers (3rd item of the task) We joined net_sales View with dim_customer on customer code, and created a stored procedure.
SELECT c.customer, ROUND(SUM(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
JOIN dim_customer c
ON n.customer_code = c.customer_code
WHERE fiscal_year=2021
GROUP BY customer
ORDER BY net_sales_mln desc
LIMIT 5;

##
SELECT product, ROUND(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales
WHERE fiscal_year=2021
GROUP BY product
ORDER BY net_sales_mln desc
LIMIT 5;

## Get top customer - store proc copy
SELECT c.customer, ROUND(SUM(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
JOIN dim_customer c
ON n.customer_code = c.customer_code
WHERE fiscal_year=in_fiscal_year and s.market=in_market
GROUP BY customer
ORDER BY net_sales_mln desc
LIMIT in_top_n;

## Get top product - store proc copy
SELECT product, ROUND(sum(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales
WHERE fiscal_year=in_fiscal_year
GROUP BY product
ORDER BY net_sales_mln desc
LIMIT in_top_n;

## PRODUCT OWNER TASK 7: Get global net sales market share % by customer (Using window function)
WITH cte1 as (SELECT c.customer, ROUND(SUM(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
JOIN dim_customer c
ON n.customer_code = c.customer_code
WHERE fiscal_year=2021
GROUP BY customer)
SELECT *, net_sales_mln*100/SUM(net_sales_mln) OVER () as net_sales_pct
FROM cte1
ORDER BY net_sales_mln desc;

## PRODUCT OWNER TASK 8: Get market share % by customer regionally (Used partition by as we needed to get the percentage contribution by the different Regions in the column)
with cte1 as (SELECT c.customer, c.region, ROUND(SUM(net_sales)/1000000,2) as net_sales_mln
FROM gdb0041.net_sales n
JOIN dim_customer c
ON n.customer_code = c.customer_code
WHERE fiscal_year=2021
GROUP BY c.customer, c.region)
SELECT *, net_sales_mln*100/SUM(net_sales_mln) OVER (partition by region) as pct_shares_region
FROM cte1
ORDER BY region, net_sales_mln desc;


SELECT p.division,
p.product, SUM(sold_quantity) as total_qty
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY p.product;

## PRODUCT OWNER TASK 9: Get top n products by division - top 3 (used multiple CTEs as each one contains a derived column, and it won't allow more measures on the same query)
with cte1 as (SELECT p.division,
p.product, SUM(sold_quantity) as total_qty
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY p.product),
cte2 as (SELECT *,
dense_rank() over(partition by division order by total_qty) as drnk
FROM cte1)
SELECT * FROM cte2 WHERE drnk<=3;

##Excercise            
with cte1 as (select
c.market,
c.region,
round(sum(gross_price_total)/1000000,2) as gross_sales_mln
from gross_sales s
join dim_customer c
on c.customer_code=s.customer_code
where fiscal_year=2021
group by market
order by gross_sales_mln desc),
cte2 as (select *,
dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
from cte1)
select * from cte2 where drnk<=2
