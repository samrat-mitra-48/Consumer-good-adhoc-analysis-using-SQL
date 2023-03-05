use gdb023;

select distinct(region) from dim_customer;
select * from dim_product;

select * from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;



# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select  distinct(market) from dim_customer
where customer='Atliq Exclusive'
and region='APAC';


# 2. What is the percentage of unique product increase in 2021 vs. 2020

with count_product as
(select 
count(distinct case when fiscal_year=2021 then product_code END ) unique_product_code2021,
count(distinct case when fiscal_year=2020 then product_code END ) unique_product_code2020
from fact_sales_monthly)

select unique_product_code2020,unique_product_code2021,
round((unique_product_code2021-unique_product_code2020)/unique_product_code2020*100,2) as prcnt_change
from count_product;
 



# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select segment, count(distinct product_code) as unique_product_counts 
from dim_product 
group by segment 
order by unique_product_counts desc;





# 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?

with count_product as(
select 
segment,
 count(distinct case when fiscal_year=2020 then product_code end) as product_count_20,
 count(distinct case when fiscal_year=2021 then product_code end) as product_count_21
 from fact_sales_monthly join dim_product using(product_code)
 group by 1)
 
 
 select segment, product_count_20,product_count_21,
 (product_count_21-product_count_20) as difference
 from count_product
 order by difference desc;
 
 
 # 5. Get the products that have the highest and lowest manufacturing costs
 with x as
(select p.product_code,p.product,mc.manufacturing_cost,
dense_rank() over(order by mc.manufacturing_cost desc) as max,
dense_rank() over(order by mc.manufacturing_cost ) as min
from
fact_manufacturing_cost mc
join dim_product p on p.product_code=mc.product_code
group by p.product)

select product_code, product,manufacturing_cost
from x where max=1 or min=1;






# 6. Top 5 customers who received 
# an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

 
 select c.customer_code,c.customer, round(avg(i.pre_invoice_discount_pct)*100,2) average_discount_percentage from fact_pre_invoice_deductions i
 join dim_customer c
 on i.customer_code=c.customer_code
 where c.market='India'
 and i.fiscal_year=2021
 group by 1,2 
 order by average_discount_percentage desc
 limit 5;
 
 # 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month
  
select monthname(s.date) as month, 
s.fiscal_year,sum(s.sold_quantity*gp.gross_price) as Gross_sales_amount  
from fact_sales_monthly s
join  dim_customer c 
on c.customer_code=s.customer_code
join fact_gross_price gp 
on gp.product_code=s.product_code
where c.customer='Atliq Exclusive'

group by month;

 
# 8.In which quarter of 2020, got the maximum total_sold_quantity?
 
select
(case when month(date) in (9,10,11) then 'q1'
 when month(date) in (12,1,2) then 'q2' 
 when month(date) in (3,4,5) then 'q3' 
 when month(date) in (6,7,8) then 'q4' END) as quarter,
 sum(sold_quantity) as maximum_total_sold_quantity
 from fact_sales_monthly
 where fiscal_year=2020
 group by quarter;




# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
with cte as
(select c.channel,
sum(s.sold_quantity*gp.gross_price) as total_sales  
from fact_gross_price gp
join fact_sales_monthly s
on gp.product_code=s.product_code
and gp.fiscal_year=s.fiscal_year

join dim_customer c
on c.customer_code=s.customer_code

where gp.fiscal_year=2021
group by c.channel)

select channel,round(total_sales,2) as gross_sales,
(total_sales)/sum(total_sales)over()*100 as percentage_of_contribution
from cte;

 
 
# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with cte as (
  select 
    p.division, 
    p.variant,
    p.product_code,
  concat(p.product, '(', p.variant, ')') as product_variant,
    sum(s.sold_quantity) as sold_quantity,
    dense_rank() over(partition by p.division order by sum(s.sold_quantity) desc) as rank_order
  from 
    dim_product p
    join fact_sales_monthly s on s.product_code = p.product_code
  where 
    s.fiscal_year = 2021
    group by 1,2,3
)
select 
  * 
from 
  cte 
where 
  rank_order <= 3;



