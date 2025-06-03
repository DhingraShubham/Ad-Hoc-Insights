-- 1) Provide the list of markets in the APAC region in which "Atliq Exclusive" operates its business.

select market 
from dim_customer
where customer ='Atliq Exclusive'
and region = 'APAC';


-- 2) What is the percentage increase of unique products sold in 2021 compared to 2020.
  
with products as 
			    (
				 select count(distinct (case when fiscal_year=2020 then product_code end)) as unique_products_2020,
						count(distinct (case when fiscal_year=2021 then product_code end)) as unique_products_2021
				 from fact_sales_monthly
				)
select *,
	   round((unique_products_2021 - unique_products_2020)*100/unique_products_2020,2) as percentage_change
from products ;


-- 3)  Provide a report with count of unique products for each segment in descending order. 

 select segment, 
		count(*) as product_count 
 from dim_product
 group by segment
 order by product_count desc ; 
 
 
 -- 4) Which segment had the most increase sales of unique products in 2021 vs 2020. 
 
with product_20 as 
                  ( select segment, count(distinct p.product_code) as product_count_2020
                    from dim_product p
					join fact_sales_monthly s  on p.product_code = s.product_code
                    where s.fiscal_year = 2020
                    group by segment
		          ),
	 product_21 as 
                  ( select segment, count(distinct p.product_code) as product_count_2021
                    from dim_product p
					join fact_sales_monthly s  on p.product_code = s.product_code
                    where s.fiscal_year = 2021
                    group by segment
		          )
select p1.segment, p1.product_count_2020, p2.product_count_2021,
       (product_count_2021 - product_count_2020) as difference
from product_20 p1
join product_21 p2  on p1.segment = p2.segment
order by difference desc;


-- 5) Get the products that have the highest and lowest manufacturing costs. 
 
select c.product_code, p.product, c.manufacturing_cost
from fact_manufacturing_cost c
join dim_product p on c.product_code = p.product_code
where manufacturing_cost in (
							(select max(manufacturing_cost) from fact_manufacturing_cost),
							(select min(manufacturing_cost) from fact_manufacturing_cost)
                            );
                            
                            
-- 6) Generate a report for top 5 customers in Indian market for fiscal year 2021 who received the 
--    pre_invoice_discount_pct more than the average pre_invoice_discount_pct. 

select p.customer_code, c.customer, round((p.pre_invoice_discount_pct*100),2) as disctount_percent
from fact_pre_invoice_deductions p
join dim_customer c on p.customer_code = c.customer_code
where fiscal_year = 2021 
and c.market = 'India'
and pre_invoice_discount_pct >= ( select avg(pre_invoice_discount_pct)
								  from fact_pre_invoice_deductions
								)
order by p.pre_invoice_discount_pct desc
limit 5;


-- 7) Generate a report for "Atliq Exclusive" having the Gross sales amount of each month for fiscal year 2020 and onwards.

select monthname(date) as month, year(date) as year, fiscal_year, customer, 
       round(sum(gross_sales)/1000000,2) as gross_sales
from gross_sales_amount 
where customer= 'Atliq Exclusive'
and fiscal_year >= 2020
group by monthname(date), year(date), fiscal_year, customer;


-- 8) Which quarter of 2020, observed the maximum total_sold_quantity 

select get_fiscal_qtr(date) as quarter, round(sum(sold_quantity)/1000000,2) as total_sold_qty
from fact_sales_monthly 
where fiscal_year = 2020
group by get_fiscal_qtr(date)
order by total_sold_qty desc ;


-- 9) Generate a report for the gross sales for the fiscal year 2021 based on the channel and with percentage contribution.

with channel_gs as 
                 ( select c.channel, round(sum(gross_sales)/1000000,2) as total_gross_sales
                   from gross_sales_amount gs
				   join dim_customer c on gs.customer_code = c.customer_code
                   where fiscal_year = 2021
                   group by c.channel
				 )
select *,
       round(total_gross_sales*100/sum(total_gross_sales) over(),2) as percentage_contribution
from channel_gs;


-- 10) Get the top 3 products in each division having highest total_sold_quantity for the fiscal_year 2021.


with sold_qty as 
		        ( select product_code, sum(sold_quantity) as total_sold_qty
                  from fact_sales_monthly s
                  where s.fiscal_year = 2021
                  group by product_code
                ),
    order_qty as 
                ( select p.division, s.product_code, p.product, s.total_sold_qty,
                         dense_rank() over(partition by division order by total_sold_qty desc) as d_rank
                  from sold_qty s 
                  join dim_product p on s.product_code = p.product_code
		        )
select *
from order_qty
where d_rank <= 3;