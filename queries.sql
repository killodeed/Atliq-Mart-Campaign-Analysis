# promo count
SELECT promo_type,count(promo_type) FROM fact_events
group by promo_type;

-- base price greater than 500 and BOGOF promo type
select * from fact_events
where base_price > 500 and promo_type = 'BOGOF';

-- store count in each city
select city, count(store_id)
from dim_stores
group by city
order by count(store_id);

-- initial and final revenue in millions
select  sum((base_price*qs_before)/1000000) as Pre_Revenue,
round(sum(case promo_type 
	when '50% OFF' then (0.5*base_price*qs_after)
    when '25% OFF' then (0.75*base_price*qs_after)
    when '33% OFF' then (0.67*base_price*qs_after)
    when '500 Cashback' then ((base_price - 500)*qs_after)
    when 'BOGOF' then (base_price*qs_after)/2
    end )/1000000, 2) as Campaign_Revenue
from fact_events;

-- campaign wise initial and final revenue
select  campaign_id, round(sum((base_price*qs_before)/1000000), 2) as Pre_Revenue,
round(sum(case promo_type 
	when '50% OFF' then (0.5*base_price*qs_after)
    when '25% OFF' then (0.75*base_price*qs_after)
    when '33% OFF' then (0.67*base_price*qs_after)
    when '500 Cashback' then ((base_price - 500)*qs_after)
    when 'BOGOF' then (base_price*qs_after)/2
    end )/1000000, 2) as Campaign_Revenue
from fact_events
group by campaign_id;

## city wise revenue distribution
select city, round(sum((base_price*qs_before)/1000000), 2) as Pre_Revenue,
round(sum(case promo_type 
	when '50% OFF' then (0.5*base_price*qs_after)
    when '25% OFF' then (0.75*base_price*qs_after)
    when '33% OFF' then (0.67*base_price*qs_after)
    when '500 Cashback' then ((base_price - 500)*qs_after)
    when 'BOGOF' then (base_price*qs_after)/2
    end )/1000000 , 2) as Campaign_Revenue
from fact_events
inner join dim_stores on fact_events.store_id = dim_stores.store_id
group by city
order by Campaign_Revenue;

-- diwali isu% increase
select dp.category, ((sum(qs_after) - sum(qs_before))/sum(qs_before))*100 as 'ISU_Percent',
	rank() 
    over (order by ((sum(qs_after) - sum(qs_before))/sum(qs_before))*100 desc) 
    AS Rank_Order
from dim_products dp
inner join fact_events f on f.product_code = dp.product_code
where f.campaign_id = 'CAMP_SAN_01'
group by dp.category
order by ISU_Percent desc;


-- Top 5 products based on IR%
with discountedPrice as (
select *,
case promo_type
	when '50% OFF' then 0.5*fe.base_price
    when '25% OFF' then 0.75*fe.base_price
	when '33% OFF' then 0.67*fe.base_price
    when '500 Cashback' then fe.base_price - 500
    when 'BOGOF' then fe.base_price/2
	else fe.base_price
end as discount_price
from fact_events fe
)
select  dp.product_name, dp.category, 
round(((sum(f.qs_after*p.discount_price) - sum(f.base_price*f.qs_before))/sum(f.base_price*f.qs_before))*100 , 2) as IR_Percent
from dim_products dp
join fact_events f on f.product_code = dp.product_code
join discountedPrice p on p.event_id = f.event_id
group by dp.product_name, dp.category
order by IR_Percent desc
limit 5;





