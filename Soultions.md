
# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct(market) from dim_customer
where customer='Atliq Exclusive'
and region='APAC';


Output:

| market      |
|-------------|
| Australia   |
| Bangladesh  |
| India       |
| Indonesia   |
| Japan       |
| Newzealand  |
| Philippines |
| South Korea |

# 2. What is the percentage of unique product increase in 2021 vs. 2020

with count_product as
(select 
count(distinct case when fiscal_year=2021 then product_code END ) unique_product_code2021,
count(distinct case when fiscal_year=2020 then product_code END ) unique_product_code2020
from fact_sales_monthly)

select unique_product_code2020,unique_product_code2021,
round((unique_product_code2021-unique_product_code2020)/unique_product_code2020*100,2) as prcnt_change
from count_product;

Output:

| unique_product_code2020 | unique_product_code2021 | prcnt_change |
|-------------------------|-------------------------|--------------|
| 245                     | 334                     | 36.33        |




# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select segment, count(distinct product_code) as unique_product_counts 
from dim_product 
group by segment 
order by unique_product_counts desc;

Output:

| segment      | unique_product_counts |
|--------------|-----------------------|
| Notebook     | 129                   |
| Accessories  | 116                   |
| Peripherals  | 84                    |
| Desktop      | 32                    |
| Storage      | 27                    |
| Networking   | 9                     |



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

 Output:
 
| segment      | product_count_20 | product_count_21 | difference |
|--------------|------------------|------------------|------------|
| Accessories  | 69               | 103              | 34         |
| Notebook     | 92               | 108              | 16         |
| Peripherals  | 59               | 75               | 16         |
| Desktop      | 7                | 22               | 15         |
| Storage      | 12               | 17               | 5          |
| Networking   | 6                | 9                | 3          |

 
 
 # 5. Get the products that have the highest and lowest manufacturing costs
 with x as
(select p.product_code,p.product, mc.manufacturing_cost,
dense_rank() over(order by mc.manufacturing_cost desc) as max,
dense_rank() over(order by mc.manufacturing_cost ) as min
from
fact_manufacturing_cost mc
join dim_product p on p.product_code=mc.product_code
group by p.product)

select product_code, product,manufacturing_cost
from x where max=1 or min=1;

Output:

| product_code | product               | manufacturing_cost |
|--------------|-----------------------|--------------------|
| A2118150101  | AQ Master wired x1 Ms | 0.892              |
| A6119110201  | AQ HOME Allin1 Gen 2  | 237.318            |




# 6. Top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

 
 select c.customer_code,c.customer, round(avg(i.pre_invoice_discount_pct)*100,2) average_discount_percentage from fact_pre_invoice_deductions i
 join dim_customer c
 on i.customer_code=c.customer_code
 where c.market='India'
 and i.fiscal_year=2021
 group by 1,2 
 order by average_discount_percentage desc
 limit 5;

 Output:
 
| customer_code | customer | average_discount_percentage |
|---------------|----------|-----------------------------|
| 90002009      | Flipkart | 30.83                       |
| 90002006      | Viveks   | 30.38                       |
| 90002003      | Ezone    | 30.28                       |
| 90002002      | Croma    | 30.25                       |
| 90002016      | Amazon   | 29.33                       |

 
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

 Output:
 
| month     | fiscal_year | Gross_sales_amount |
|-----------|-------------|--------------------|
| September | 2020        | 28622941.64        |
| October   | 2020        | 31394855.81        |
| November  | 2020        | 47479184.76        |
| December  | 2020        | 30164858.23        |
| January   | 2020        | 29155653.65        |
| February  | 2020        | 24070599.44        |
| March     | 2020        | 19916601.38        |
| April     | 2020        | 12283602.26        |
| May       | 2020        | 20791273.89        |
| June      | 2020        | 18887316.23        |
| July      | 2020        | 24196784.22        |
| August    | 2020        | 16962830.17        |


 
# 8. In which quarter of 2020, got the maximum total_sold_quantity?
 
select
(case when month(date) in (9,10,11) then 'q1'
 when month(date) in (12,1,2) then 'q2' 
 when month(date) in (3,4,5) then 'q3' 
 when month(date) in (6,7,8) then 'q4' END) as quarter,
 sum(sold_quantity) as maximum_total_sold_quantity
 from fact_sales_monthly
 where fiscal_year=2020
 group by quarter;

Output:

| quarter | maximum_total_sold_quantity |
|---------|-----------------------------|
| q1      | 7005619                     |
| q2      | 6649642                     |
| q3      | 2075087                     |
| q4      | 5042541                     |



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

Output:

| channel     | gross_sales  | percentage_of_contribution |
|-------------|--------------|-----------------------------|
| Direct      | 257532002.7  | 15.47073932                 |
| Retailer    | 1219081640   | 73.23398284                 |
| Distributor | 188025630.9  | 11.29527784                 |

 
 
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

Output:

| division | variant             | product_code | product_variant               | sold_quantity | rank_order |
|----------|---------------------|--------------|-------------------------------|---------------|------------|
| N & S    | Premium             | A6720160103  | AQ Pen Drive 2 IN 1(Premium)  | 701373        | 1          |
| N & S    | Plus                | A6818160202  | AQ Pen Drive DRC(Plus)        | 688003        | 2          |
| N & S    | Premium             | A6819160203  | AQ Pen Drive DRC(Premium)     | 676245        | 3          |
| P & A    | Standard 2          | A2319150302  | AQ Gamers Ms(Standard 2)      | 428498        | 1          |
| P & A    | Standard 1          | A2520150501  | AQ Maxima Ms(Standard 1)      | 419865        | 2          |
| P & A    | Plus 2              | A2520150504  | AQ Maxima Ms(Plus 2)          | 419471        | 3          |
| PC       | Standard Blue       | A4218110202  | AQ Digit(Standard Blue)       | 17434         | 1          |
| PC       | Plus Red            | A4319110306  | AQ Velocity(Plus Red)         | 17280         | 2          |
| PC       | Premium Misty Green | A4218110208  | AQ Digit(Premium Misty Green) | 17275         | 3          |

