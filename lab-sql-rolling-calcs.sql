-- 1 Get number of monthly active customers.
-- step 1: first i'll create a view with all the data i'm going to need:
create or replace view user_activity as
select customer_id, convert(rental_date, date) as Activity_date,
date_format(convert(rental_date,date), '%m') as Activity_Month,
date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;
select * from sakila.user_activity;

-- step 2: getting the total number of active user per month and year
create or replace view sakila.monthly_active_users as
select Activity_year, Activity_Month, count(distinct customer_id) as Active_users
from sakila.user_activity
group by Activity_year, Activity_Month
order by Activity_year asc, Activity_Month asc;
select * from monthly_active_users;


-- 2 Active users in the previous month.
select 
   Activity_year, 
   Activity_month,
   Active_users, 
   lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month -- lag(Active_users, 2) -- partition by Activity_year
from monthly_active_users;


with cte_usage as
(
	select Activity_year, Activity_month, Active_users,
	lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
    from monthly_active_users)
    select * from cte_usage;


with cte_view as 
(
	select 
	Activity_year, 
	Activity_month,
	Active_users, 
	lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
	from monthly_active_users
)
select 
   Activity_year, 
   Activity_month, 
   Active_users, 
   Last_month, 
   (Active_users - Last_month) as Difference 
from cte_view;


-- 3 Percentage change in the number of active customers.
with cte_usage as
(
	select Activity_year, Activity_month, Active_users,
	lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
    from monthly_active_users)
select *, (Active_users-Last_month)/Active_users*100 as percentage from cte_usage;



-- 4 Retained customers every month.

with cte_view as 
(
	select 
	Activity_year, 
	Activity_month,
	Active_users, 
	lag(Active_users) over (order by Activity_year, Activity_Month) as Last_month
	from monthly_active_users
)
select m1.Activity_year, m1.Activity_month, m1.Active_users, m2.Activity_year, m2.Activity_month, m2.Active_users Previous_month_users
from cte_view m1
left join cte_view m2
on m1.Activity_year = m2.Activity_year -- case when m1.Activity_month = 1 then m1.Activity_year + 1 else m1.Activity_year end
and m1.Activity_month =  m2.Activity_month+1;


/* Stuff to test
select date(v.visited_at),
       count(case when v.visited_at = vv.minva then user_id end) as num_new_users,
       (count(distinct user_id) - count(case when v.visited_at = vv.minva then user_id end)
       ) as num_repeat_users
from visits v 
join
     (select user_id, min(visited_at) as minva
      from visits t
      group by user_id
     ) vv
     on v.user_id = vv.user_id
group by date(v.visited_at)
order by date(v.visited_at);

use sakila;
select customer_id,
case 
	when sum(monthname(rental_date) = 'June') > 0 then 1 
    else 0
end as june_rentals
from sakila.rental
group by customer_id
having june_rentals = 1;


use sakila;
select customer_id,
case 
	when sum(monthname(rental_date) = 'June') > 0 then 1 
    else 0
end as june_rentals
from sakila.rental
group by customer_id
having june_rentals = 1; */
