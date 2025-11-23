 -- Создаю таблицу customer
 create table customer (
	customer_id bigint primary key,
	first_name text,
	last_name text,
	gender varchar(10),
	DOB date,
	job_title varchar(100),
	job_industry_category varchar(50),
	wealth_segment varchar(50),
	deceased_indicator text, -- Временно, после загрузки данных сделаю маппинг и заменю на boolean
	owns_car text, -- Временно, после загрузки данных сделаю маппинг и заменю на boolean
	address text,
	postcode varchar(10),
	state varchar(50),
	country varchar(50),
	property_valuation smallint
);

/*Данный скрипт выполняла после того, как загрузила данные из файла customer.csv через импорт.
Для того, чтобы написать корректный case проводила предварительный анализ данных в таблице customer.csv*/
update customer
set deceased_indicator =
		case 
			when deceased_indicator in ('Y') then 'true'
			when deceased_indicator in ('N') then 'false'
			else null
		end,
	owns_car = 
		case 
			when owns_car in ('Yes') then 'true'
			when owns_car in ('No') then 'false'
			else null
		end;
-- Заменилы тип text на boolean
alter table customer
	alter column deceased_indicator type boolean using deceased_indicator::boolean,
	alter column owns_car type boolean using owns_car::boolean;

--drop table customer, orders;

 -- Создаю таблицу orders
 create table orders (
	order_id bigint primary key,
	customer_id bigint,
	order_date date,
	online_order boolean, -- Тут сразу сделала boolean, так как данные, которые находятся в данной колонке в файле product.csv, соответствуют типу boolean
	order_status varchar(50)
);

 -- Создаю таблицу product
 create table product (
	product_id bigint, -- В данных есть дубли, поэтому сначала создаю структуру без PK, чтобы импорт не выдал ошибок. Обработка дублей будет ниже
	brand varchar(50),
	product_line varchar(50),
	product_class varchar(50),
	product_size varchar(50),
	list_price numeric(10,2),
	standard_cost numeric(10,2)
);

-- Удаляю дубли, - оставляю последнее введенное значение
delete from product
where ctid not in (
	select max(ctid)
	from product
	group by product_id
);
-- Проверяю, что дублей в product_id больше нет
select product_id, count(*)
from product
group by product_id
having count(*) > 1;

-- Теперь назначаю product_id, как PK
alter table product
add primary key (product_id);

-- Создаю таблицу order_item_id
create table order_item_id (
	order_item_id bigint primary key,
	order_id bigint,
	product_id bigint,
	quantity numeric(10,2),
	item_list_price_at_sale numeric(10,2),
	item_standard_cost_at_sale numeric(10,2)
);

	
	