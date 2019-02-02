/* Product Revenue/Earnings by Publisher */
select product_revenue.sale_id, 
       product_revenue.sale_name, 
       product_revenue.revenue,
       product_revenue.avg_price, 
       product_earnings.earnings,
       product_earnings.avg_earnings_per_sale,
       product_revenue.quantity_sold 
  from(
/* Revenue by Product by Pub */
select order_line_items.sale_id as sale_id, 
       sales.name as sale_name, 
       concat('$',format(sum(order_line_items.paid_price_cents)/100, 2)) as revenue, 
       concat('$',format(avg(order_line_items.paid_price_cents)/100, 2)) as avg_price, 
       count(sales.id) as quantity_sold
from order_line_items
join sales on (sales.id = order_line_items.sale_id)
where publisher_id = 51  -- <-- Change Publisher ID
  and date(convert_tz(order_line_items.created_at, 'UTC', 'America/Los_Angeles')) between '2016-11-10' and '2016-12-05'  -- <-- Change Date Range
  and order_line_items.paid_price_cents > 0
group by sales.name
) as product_revenue 
  join (
/* Earnings by Sale by Pub */
select sales.id as id, 
       sales.name, 
       concat('$',format(sum(earnings.amount_in_cents)/100, 2)) as earnings, 
       concat('$',format(avg(earnings.amount_in_cents)/100, 2)) as avg_earnings_per_sale 
from publishers
join earnings on (earnings.earner_id = publishers.id)       
join sales on (sales.id = earnings.sale_id)
where publishers.id = 51  -- <-- Change Publisher ID
  and earnings.earner_type = "Publisher"
  and date(convert_tz(earnings.created_at, 'UTC', 'America/Los_Angeles')) between '2016-11-10' and '2016-12-05' -- <-- Change Date Range
  and earnings.amount_in_cents > 0
group by sales.name
) as product_earnings on (product_earnings.id = product_revenue.sale_id)
  order by quantity_sold desc
;
