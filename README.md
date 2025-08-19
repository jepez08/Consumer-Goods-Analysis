# Atliq Global Sales SQL Project

## Overview
This project demonstrates advanced SQL data analysis skills through **9 Product Owner–driven tasks** for **Atliq Global Sales**.  
The goal was to analyze product and market performance, create reusable SQL queries, and deliver insights for business decision-making.

The project is organized into two scripts:
1. `1 - GS for X customer` – Product-level and customer sales analysis (Tasks 1-5) 
2. `2 - Rankings (advanced queries)` – Market share, net sales, and top-performer analysis (Tasks 6-9)

---

## Product Owner Tasks (Highlights)

The Atliq Product Owner requested **9 SQL tasks**, each with multiple sub-steps:

**Task 1: Individual Product Sales (Monthly)**  
- Calculated sold quantity and total gross sales for each product in FY 2021 for **Croma India**.
- Create a User-Defined Function to get the fiscal year.
- Joined `fact_sales_monthly` with `dim_product` and `fact_gross_price` to compute gross totals.

**Task 2: Monthly Total Sales Report**  
- Aggregated total monthly gross sales for **Croma India**.

**Task 3: Yearly Sales Report**  
- Generated annual gross sales totals for Croma India by **fiscal year**.

**Task 4: Monthly Gross Sales Stored Procedure**  
- Built a stored procedure to quickly retrieve monthly gross sales for any given customer (repetitive task automation).

**Task 5: Market Badge Classification**  
- Assigned **Gold/Silver badges** to markets based on sales thresholds:  
  - **Gold**: Total sold quantity > 5 million  
  - **Silver**: Otherwise

**Task 6: Top Performers Analysis**  
- Created a fiscal year column on fact_sales_monthly to reduce query time and more joins.
- Identified **top markets, top products, and top customers** by net sales for a selected fiscal year.  
- Created layered **Views** and **stored procedures** to streamline reporting.

**Task 7: Global Market Share by Customer**  
- Computed **net sales % contribution per customer globally** using **window functions**.

**Task 8: Regional Market Share by Customer**  
- Computed **market share % by region** using `PARTITION BY` to analyze contributions across different regions.

**Task 9: Top N Products by Division**  
- Retrieved **top 3 products per division** using **multiple CTEs** for modular and maintainable calculations.

---

## Tech Stack & SQL Concepts
- SQL (MySQL)  
- Stored Procedures & User-Defined Functions
- Joins  
- Common Table Expressions (CTEs)  
- Views for layered calculations  
- Window Functions for rankings & market share, using partition by on determined cases  
- Query optimization by replacing UDFs with precomputed fiscal year column

---
