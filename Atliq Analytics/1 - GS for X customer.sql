
### PRODUCT OWNER TASK: Individual product sales (aggr on monthly basis at product code) for Croma India FY=2021 to track product sales
# 1. Month, 2. Product Name, 3. Variant, 4. Sold Qty, 5. Gross Price per Item, 6. Gross Price Total

# Find Customer code
SELECT * FROM gdb0041.dim_customer
where customer = "Croma";

# Create User Defined Function to get the fiscal year
CREATE DEFINER=`root`@`localhost` FUNCTION `get_fiscal_year`(
calendar_date DATE
) RETURNS int
    DETERMINISTIC
BEGIN
	DECLARE fiscal_year INT;
	SET fiscal_year = YEAR(DATE_ADD(calendar_date, INTERVAL 4 MONTH));
	RETURN fiscal_year;
END;

# Result query: Join fact_sales_monthly s with dim_product p to get date, product code, product, variant, and sold quantity.
# Joined then with fact_gross_price g to get ross price and calculate total multiplying by sold quantity.

SELECT s.date, s.product_code, 
p.product, p.variant, s.sold_quantity,
g.gross_price,
ROUND(g.gross_price*s.sold_quantity) as gross_price_total
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
join fact_gross_price g
on g.product_code = s.product_code and 
g.fiscal_year = get_fiscal_year (s.date)
where customer_code = 90002002 and
get_fiscal_year(date) = 2021 and
get_fiscal_quarter(date) = "Q4"
order by date desc


## PRODUCT OWNER TASK 2: Aggregate monthly total sales report from Croma India
## 1. Month, 2. Total Gross sales amount to Croma India in this month
SELECT 
s.date,
SUM(ROUND(g.gross_price*s.sold_quantity,2)) as monthly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON g.product_code = s.product_code and
g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
GROUP BY s.date
ORDER BY date asc;

## PRODUCT OWNER TASK 3: Yearly report for Croma India
## 1. Fiscal Year, 2. Total Gross Sales amount In that year from Croma
SELECT 
get_fiscal_year(s.date) as fiscal_year,
SUM(ROUND(g.gross_price*s.sold_quantity, 2)) as yearly_sales
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON g.product_code = s.product_code and
g.fiscal_year = get_fiscal_year(s.date)
where customer_code = 90002002
GROUP BY get_fiscal_year(s.date)
ORDER BY fiscal_year asc;

## PRODUCT OWNER TASK 4: Created a Stored Procedure to get monthly gross sales for a determined customer (repetitive task)
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_sales_for_customer`(c_code INT)
BEGIN
	SELECT 
	s.date,
	SUM(ROUND(g.gross_price*s.sold_quantity,2)) as monthly_sales
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
	ON g.product_code = s.product_code and
	g.fiscal_year = get_fiscal_year(s.date)
	where c_code = c_code
	GROUP BY s.date;
END;
    
## PRODUCT OWNER TASK 5: Determine the market badge (gold, silver) based on total sold qty > 5 million = Gold. Input: Market and Fiscal Year; Output: Market badge
SELECT SUM(sold_quantity) as total_quantity
FROM fact_sales_monthly s
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE get_fiscal_year(s.date)=2021 and market='India'
GROUP BY c.market