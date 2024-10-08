Ad Hoc Requests along with the SQL Queries:-
  
1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
    select market
    from dim_customer
    where customer = "Atliq Exclusive" and region = "APAC";

2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

  with cte_2020 as(
  	select count(distinct product_code) as unique_products_2020
  	from fact_sales_monthly s
  	where s.fiscal_year = 2020
  ),
  cte_2021 as(
  	select count(distinct product_code) as unique_products_2021
  	from fact_sales_monthly s
  	where s.fiscal_year = 2021
      )
  select unique_products_2020,unique_products_2021,
  	   round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as pct_change
  from cte_2020,cte_2021

3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields,
segment
product_count

    select segment, count(product_code) as product_count
    from dim_product
    group by segment
    order by product_count desc;


4.Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
segment
product_count_2020
product_count_2021
difference

    with cte_2020 as (
    	select p.segment, count(distinct p.product_code) as product_count_2020
    	from dim_product p
    	join fact_sales_monthly s
    	on p.product_code = s.product_code
    	where s.fiscal_year = 2020
    	group by segment
    	order by product_count_2020 desc
        ),
    cte_2021 as (
    	select p.segment, count(distinct p.product_code) as product_count_2021
    	from dim_product p
    	join fact_sales_monthly s
    	on p.product_code = s.product_code
    	where s.fiscal_year = 2021
    	group by segment
    	order by product_count_2021 desc
        )
    select cte_2021.segment,product_count_2020,product_count_2021,
    product_count_2021-product_count_2020 as difference
    from cte_2021 
    join cte_2020
    on cte_2021.segment = cte_2020.segment
    order by difference desc


5. Get the products that have the highest and lowest manufacturing costs.The final output should contain these fields,
product_code
product
manufacturing_cost

    select 
    p.product_code, p.product, m.manufacturing_cost
    from dim_product p
    join fact_manufacturing_cost m
    on p.product_code = m.product_code 
    where m.manufacturing_cost =  (select min(manufacturing_cost) from fact_manufacturing_cost) or
    	  m.manufacturing_cost =  (select max(manufacturing_cost) from fact_manufacturing_cost);

6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

    select c.customer,
    	   c.customer_code,
           concat(round(avg(pre_invoice_discount_pct)*100,2),"%") as avg_discount_pct
    from fact_pre_invoice_deductions pre
    join dim_customer c
    on pre.customer_code = c.customer_code
    where c.market = "India" and fiscal_year =2021 
    group by c.customer, c.customer_code
    order by avg(pre_invoice_discount_pct)*100 desc
    limit 5; 

7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns:
Month
Year
Gross sales Amount

    select monthname(s.date) as month, g.fiscal_year,
    	   round(sum(g.gross_price * s.sold_quantity)/1000000,2) as gross_sales_mln
    from fact_sales_monthly s
    join fact_gross_price g
    on s.product_code = g.product_code
    join dim_customer c
    on s.customer_code = c.customer_code
    and s.fiscal_year = g.fiscal_year
    where customer = "Atliq Exclusive"
    group by monthname(s.date),g.fiscal_year
    limit 1000000;

8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

      select concat("Q",ceiling(month(date_add(s.date,interval 4 month))/3)) as quarter_no,
      sum(sold_quantity) as total_sold_quantity
      from fact_sales_monthly s
      where fiscal_year = 2020
      group by quarter_no
      order by total_sold_quantity desc

9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields:
channel
gross_sales_mln
percentage

    with gross_sales as(
    select distinct channel,
    	   round(sum(gross_price*sold_quantity)/1000000,2) as gross_sales_mln
    from fact_sales_monthly s
    join dim_customer c 
    on s.customer_code = c.customer_code
    join fact_gross_price g
    on s.product_code = g.product_code
    and s.fiscal_year = g.fiscal_year
    where s.fiscal_year=2021
    group by channel
    )
    select *,
           gross_sales_mln*100/sum(gross_sales_mln) over() as pct
           from gross_sales
           order by pct desc


10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields:
division
product_code
product
total_sold_quantity
rank_order

    with cte1 as(
    select division, p.product_code,product,
    sum(s.sold_quantity) as total_sold_quantity
    from fact_sales_monthly s
    join dim_product p
    on s.product_code = p.product_code
    where s.fiscal_year = 2021
    group by division,p.product_code,product
    ),
    cte2 as(select *,
    dense_rank() over(partition by division order by total_sold_quantity) as rank_no
    from cte1)
    select * from cte2 where rank_no <=3
