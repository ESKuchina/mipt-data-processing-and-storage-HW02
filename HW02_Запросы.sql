/*Вывести все уникальные бренды, у которых есть хотя бы один продукт со стандартной стоимостью выше 1500 долларов,
и суммарными продажами не менее 1000 единиц.*/
select p.brand
from product p 
left join order_item_id on p.product_id = order_item_id.product_id
group by p.brand
having 
	count(*) filter (where standard_cost > 1500) > 0
	and sum(order_item_id.quantity)>= 1000;


/*Для каждого дня в диапазоне с 2017-04-01 по 2017-04-09 включительно вывести количество подтвержденных онлайн-заказов
и количество уникальных клиентов, совершивших эти заказы.*/
select
	o.order_date ,
	count(*) as confirmed_online_orders,
	count(distinct o.customer_id ) as unique_customers
from orders o 
where
	o.order_date between '2017-04-01'::date and '2017-04-09'::date
	and o.online_order = true
	and o.order_status = 'Approved'
group by o.order_date
order by o.order_date;

/*Вывести профессии клиентов:
из сферы IT, чья профессия начинается с Senior;
из сферы Financial Services, чья профессия начинается с Lead.
Для обеих групп учитывать только клиентов старше 35 лет. Объединить выборки с помощью UNION ALL.*/
select
	c.job_title
from customer c
where
	c.job_title::varchar like 'Senior%'
	and c.job_industry_category = 'IT'
	and age(c.dob) > interval '35 years'

union all

select
	c.job_title
from customer c
where
	c.job_title::varchar like 'Lead%'
	and c.job_industry_category = 'Financial Services'
	and age(c.dob) > interval '35 years';

-- Вывести бренды, которые были куплены клиентами из сферы Financial Services, но не были куплены клиентами из сферы IT.
select distinct p.brand
from customer c
inner join orders o
    on c.customer_id = o.customer_id
inner join order_item_id oi
    on o.order_id = oi.order_id
inner join product p
    on oi.product_id = p.product_id
where c.job_industry_category = 'Financial Services'

except

select distinct p.brand
from customer c
inner join orders o
    on c.customer_id = o.customer_id
inner join order_item_id oi
    on o.order_id = oi.order_id
inner join product p
    on oi.product_id = p.product_id
where c.job_industry_category = 'IT';

/*Вывести 10 клиентов (ID, имя, фамилия), которые совершили наибольшее количество онлайн-заказов (в штуках) брендов
Giant Bicycles, Norco Bicycles, Trek Bicycles, при условии,
что они активны и имеют оценку имущества (property_valuation) выше среднего среди клиентов из того же штата.*/
select
    c.customer_id,
    c.first_name,
    c.last_name,
    count(*) as online_orders_count
from customer c
join orders o
    on c.customer_id = o.customer_id
join order_item_id oi
    on o.order_id = oi.order_id
join product p
    on oi.product_id = p.product_id
where
    o.online_order = true
    and c.deceased_indicator = false
    and p.brand in ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
    and c.property_valuation >
        (
            select avg(c2.property_valuation)
            from customer c2
            where c2.state = c.state
        )
group by
    c.customer_id, c.first_name, c.last_name
order by
    online_orders_count desc
limit 10;

/*Вывести всех клиентов (ID, имя, фамилия), у которых нет подтвержденных онлайн-заказов за последний год,
но при этом они владеют автомобилем и их сегмент благосостояния не Mass Customer.*/
select
    c.customer_id,
    c.first_name,
    c.last_name
from customer c
where
    c.owns_car = true
    and c.wealth_segment <> 'Mass Customer'
    and not exists (
        select 1
        from orders o
        where o.customer_id = c.customer_id
          and o.online_order = true
          and o.order_status = 'Approved'
          and o.order_date >= (
                select max(order_date) - interval '1 year'
                from orders
          )
    );

/*Вывести всех клиентов из сферы 'IT' (ID, имя, фамилия),
которые купили 2 из 5 продуктов с самой высокой list_price в продуктовой линейке Road.*/
select
    c.customer_id,
    c.first_name,
    c.last_name
from customer c
join orders o
    on c.customer_id = o.customer_id
join order_item_id oi
    on o.order_id = oi.order_id
where
    c.job_industry_category = 'IT'
    and oi.product_id in (
        select product_id
        from product
        where product_line = 'Road'
        order by list_price desc
        limit 5
    )
group by
    c.customer_id,
    c.first_name,
    c.last_name
having
    count(distinct oi.product_id) = 2;



/*Вывести клиентов (ID, имя, фамилия, сфера деятельности) из сфер IT или Health,
которые совершили не менее 3 подтвержденных заказов в период 2017-01-01 по 2017-03-01,
и при этом их общий доход от этих заказов превышает 10 000 долларов.
Разделить вывод на две группы (IT и Health) с помощью UNION.*/
-- ГРУППА IT
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category as industry
from customer c
join orders o
    on c.customer_id = o.customer_id
join order_item_id oi
    on o.order_id = oi.order_id
where
    c.job_industry_category = 'IT'
    and o.order_status = 'Approved'
    and o.order_date >= '2017-01-01'
    and o.order_date <= '2017-03-01'
group by
    c.customer_id, c.first_name, c.last_name, c.job_industry_category
having
    count(distinct o.order_id) >= 3
    and sum(oi.item_list_price_at_sale) > 10000

union

-- ГРУППА Health
select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category as industry
from customer c
join orders o
    on c.customer_id = o.customer_id
join order_item_id oi
    on o.order_id = oi.order_id
where
    c.job_industry_category = 'Health'
    and o.order_status = 'Approved'
    and o.order_date >= '2017-01-01'
    and o.order_date <= '2017-03-01'
group by
    c.customer_id, c.first_name, c.last_name, c.job_industry_category
having
    count(distinct o.order_id) >= 3
    and sum(oi.item_list_price_at_sale) > 10000;








	
