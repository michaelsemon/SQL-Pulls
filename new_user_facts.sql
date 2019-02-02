select
	users.id as user_id,
	users.created_at as user_created_date,
	first_paid_order_id,
	first_paid_order_date,
	paid_order_count,
	lifetime_revenue_in_cents,
	first_freebie_order_id,
	first_freebie_order_date,
	first_entry_id,
	first_entry_date,
	bundle_purch_count,
	physical_order_count,

	--registration source
	case
		when (first_paid_order_date < first_freebie_order_date)
			and (first_paid_order_date < first_entry_date)
			and first_paid_order_date is not null
		then 'paid order'

		when (first_freebie_order_date < first_paid_order_date)
			and (first_freebie_order_date < first_entry_date)
			and first_freebie_order_date is not null
		then 'freebie'

		when (first_entry_date < first_paid_order_date)
			and (first_entry_date < first_freebie_order_date)
			and first_entry_date is not null
		then 'giveaway'
	else 'other'
	end as registration_source

from users

left join(

-- first paid order info
select
	u.id as user_id,
	min(o.id) as first_paid_order_id,
	min(o.completed_at) as first_paid_order_date,
	count(o.id) as paid_order_count,
	sum(o.price_in_cents) as lifetime_revenue_in_cents
from users as u
left join orders as o on (o.user_id = u.id)
where o.price_in_cents > 0
	and o.completed_at is not null
group by u.id
) as first_orders on first_orders.user_id = users.id

left join(

-- first freebie info
select
	o.user_id as user_id,
	min(o.id) as first_freebie_order_id,
	min(o.completed_at) as first_freebie_order_date
from orders as o
----
where o.sale_price_in_cents = 0
	and o.completed_at is not null
group by o.user_id
) as first_freebie on first_freebie.user_id = first_orders.user_id

left join(

-- first giveaway info
select
	e.user_id as user_id,
	min(e.id) as first_entry_id,
	min(e.created_at) as first_entry_date
from entries as e
group by e.user_id
) as first_giveaway on first_giveaway.user_id = first_freebie.user_id

left join(

-- bundle purchase count
select
	u.id as user_id,
	count(*) as bundle_purch_count
from sales as s
left join order_stats as os on (os.sale_id = s.id)
left join orders as o on (o.id = os.order_id)
left join users as u on (u.id = o.user_id)
where s.sale_type_id = 4
	or s.sale_type_id = 5
group by u.id
) as bundle_count on bundle_count.user_id = first_giveaway.user_id

left join(

-- physical order count
select
	u.id as user_id,
	count(*) as physical_order_count
from sales as s
left join categories as c on (c.id = s.category_id)
left join order_stats as os on (os.sale_id = s.id)
left join orders as o on (o.id = os.order_id)
left join users as u on (u.id = o.user_id)
where (c.ancestry like '92%'  -- gadgets
  or c.ancestry like '93%') -- lifestyle
  and os.sum_amount_in_cents = 0
group by u.id
) as physical_orders on physical_orders.user_id = bundle_count.user_id

order by users.id asc
;






----------notes --------
select
	case
		when (first_paid_order_date < first_freebie_order_date)
			and (first_paid_order_date < first_entry_date)
			and first_paid_order_date is not null
		then 'paid order'

		when (first_freebie_order_date < first_paid_order_date)
			and (first_freebie_order_date < first_entry_date)
			and first_freebie_order_date is not null
		then 'freebie'

		when (first_entry_date < first_paid_order_date)
			and (first_entry_date < first_freebie_order_date)
			and first_entry_date is not null
		then 'giveaway'
	else 'other'
