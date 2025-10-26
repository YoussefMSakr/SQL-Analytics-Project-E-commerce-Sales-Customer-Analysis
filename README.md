# SQL-Projects
SQL Advanced Analytics project
# SQL Advanced Analytics Project

# Overview

This project demonstrates                                     **advanced data analytics using SQL**  
It includes multiple analytical layers such as time-based analysis, segmentation, performance evaluation, and KPI reporting — designed for professional business insights.

---

#Objectives
- Perform sales trend analysis over time (Yearly & Monthly).
- Calculate cumulative and moving average metrics.
- Evaluate product performance against average and previous years.
- Identify top categories contributing to overall revenue.
- Segment products and customers based on spending and lifespan.
- Build automated views for **Customer** and **Product Reports**.

---

# Tools and Environment
- Microsoft SQL Server  
- T-SQL (Transact-SQL)  
- AdventureWorks-style data model  
- Fact & Dimension tables:
  - `gold.fact_sales`
  - `gold.dim_products`
  - `gold.dim_customers`

---

# Key Analyses

# Change Over Time Analysis
Tracks yearly and monthly sales trends, customer growth, and order volume.

# Cumulative Analysis
Uses SQL **window functions** (`OVER`, `PARTITION BY`, `LAG`) to calculate:
- Running totals  
- Moving averages  

# Performance Analysis
Compares product performance with:
- Average sales  
- Previous year’s results  
- Classification into “Above”, “Below”, or “Average” performers.

# Part-to-Whole Analysis
Finds contribution of each **category** to total company sales with percentage shares.

# Data Segmentation
Segments both:
- **Products** by cost range (Below 100, 100–500, etc.)
- **Customers** by spending behavior (VIP, Regular, New).

# Reporting Views
Two automated dashboards built as SQL Views:
1. `dbo.report_customer` → Customer lifetime, segments, AOV, recency.  
2. `dbo.product_report` → Product performance, sales KPIs, monthly averages.

---

# Insights Generated
- Identification of high-performing and low-performing products.  
- Clear visibility into customer segmentation and retention.  
- Monthly and yearly performance comparison for management reporting.  

---

# Author
Major General Data Analyst / Youssef Sakr  
Advanced Data Analytics & SQL Project (2025)
