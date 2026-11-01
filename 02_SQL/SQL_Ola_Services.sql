```sql
create table dim_date (
    date_key date primary key,
    month int not null,
    quarter int not null,
    year int not null,
    is_crisis_period boolean not null default false
);

create table dim_city (
    city_key serial primary key,
    city_std varchar(100) not null,
    state varchar(100),
    rto_code varchar(20)
);

create table dim_service_center (
    center_id varchar(20) primary key,
    city_key int references dim_city(city_key),
    opened_date date,
    capacity int
);

create table dim_oem (
    oem varchar(50) primary key
)

create table dim_part (
    part_code varchar(20) primary key,
    part_name varchar(100)
);

create table dim_vehicle_customer (
    chassis_no varchar(20) primary key,
    customer_id varchar(20),
    vehicle_reg_no varchar(20),
    mobile_hash varchar(20),
    model varchar(20),
    city_key int references dim_city(city_key)
);

fact tables, referencing the dimensions:

create table fact_sales (
    sale_id serial primary key,
    date_key date references dim_date(date_key),
    city_key int references dim_city(city_key),
    model varchar(20) not null,
    units_sold int not null check (units_sold >= 0),
    avg_selling_price numeric(10,2)
);

create table fact_complaints (
    ticket_id varchar(20) primary key,
    customer_id varchar(20),
    date_key date references dim_date(date_key),
    city_key int references dim_city(city_key),
    center_id varchar(20) references dim_service_center(center_id),
    component varchar(50),
    status varchar(20) not null,
    severity varchar(20),
    csat_score int check (csat_score between 1 and 5),
    tat_days int,
    resolution_date date
);

create table fact_jobcards (
    jobcard_id varchar(20) primary key,
    chassis_no varchar(20) references dim_vehicle_customer(chassis_no),
    center_id varchar(20) references dim_service_center(center_id),
    date_key date references dim_date(date_key),
    close_date date,
    parts_cost numeric(10,2),
    labour_cost numeric(10,2),
    linked_ticket_id varchar(20) references fact_complaints(ticket_id),
    technician_id varchar(20)
);

create table fact_warranty (
    claim_id varchar(20) primary key,
    chassis_no varchar(20) references dim_vehicle_customer(chassis_no),
    date_key date references dim_date(date_key),
    component varchar(50),
    claim_amount_inr numeric(10,2)
);

--creating staging tables for csv import
select * from staging_complaints_2023

create table staging_complaints (
    ticket_id text,
    customer_id text,
    vehicle_reg_no text,
    city text,
    complaint_date date,
    channel text,
    complaint_text text,
    component_tag text,
    severity text,
    status text,
    resolution_date date,
    tat_days int,
    csat_score int,
    assigned_center_id text
);

create table staging_sales(
key text,
sale_date date,
model text,
units_sold int,
revenue_in_the_archived_sales_legacy int,
avg_selling_price_inr int,
dealer_type text,
booking_channel text
);

create table staging_jobcard(
job_jobcard_id text,
center_id text,
chassis_no text,
mobile_hash text,
open_date date,
close_date date,
issue_category text,
parts_replaced text,
parts_cost_inr int,
labour_cost_inr int,
technician_id text,
status text,
linked_ticket_id text);

create table staging_ola_sales_2023(
sale_date date,
city text,	
state text,
model text,
units_sold int,
avg_selling_price_inr int,
dealer_type text,
booking_channel text
);

alter table staging_ola_sales_2023
rename to staging_ola_sales_2024;

create table staging_vahan_competitor_registrations
(reg_date date,
city text,
oem text,
vehicle_class text,
registrations int
);

-- 6. app store reviews
create table staging_app_reviews (
    review_id text,
    review_date date,
    platform text,
    rating int,
    review_text text,
    helpful_votes int,
    app_version text,
    reply_from_ola text
);

-- 7. service centers master
create table staging_service_centers (
    center_id text,
	center_name text,
    city text,
	state text,
    opened_date date,
    capacity_jobs_per_day int,
  technicians_count int,
  center_type text
);

-- 8. job cards 2024
create table staging_jobcards (
    jobcard_id text,
    chassis_no text,
    center_id text,
    open_date date,
    close_date date,
    issue_category text,
    parts_cost numeric,
    labour_cost numeric,
    linked_ticket_id text,
    technician_id text
);

-- 9. spare parts consumption
create table staging_spare_parts (
    week_start date,
	center_id text,
    part_code text,
	part_name text,
    qty_consumed int,
    stockout_days int,
	reorder_flag text

);
alter table staging_spare_parts 
add column part_name text, 
add column reorder_flag text;
alter table staging_spare_parts
rename column week to ;
select * from staging_spare_parts

-- 10. warranty claims


  
-- 11. social media posts

	drop table if exists staging_social_media;						

create table staging_social_media (
    engagement_comments int,
    engagement_likes int,
    engagement_shares int,
    is_verified boolean,
	location_tag text,
    platform text,
    post_id text,
		date date,
		text text,
    user_handle_hash text
);

-- 12. nch/ccpa complaints

drop table if exists staging_nch_ccpa;

create table  staging_nch_ccpa (
nch_ref_id	text,
filed_date	date,
state text,
category text,
status text,	
escalated_to_ccpa boolean,
resolution_days	int,
compensation_inr int
);

-- 13. competitor incidents
drop table if exists  staging_competitor_incidents;
create table staging_competitor_incidents (
    incident_id text,
    oem text,
    date date,
    incident_type text,
    units_affected int,
    resolution_days int,
    source text
);
-----------------------------------------------------------

--taking all the dates from these 4 tables, removing duplicates, and putting them in one new table.
drop table if exists dim_date cascade;

create table dim_date as
select distinct sale_date as date_key from staging_ola_sales_2024
union
select distinct sale_date from staging_merged_sales_2023
union
select distinct complaint_date from staging_complaints_2023
union
select distinct complaint_date from staging_complaints_2024;

alter table dim_date add column month int;
alter table dim_date add column quarter int;
alter table dim_date add column year int;
alter table dim_date add column is_crisis_period boolean;

update dim_date
set month = extract(month from date_key),
    quarter = extract(quarter from date_key),
    year = extract(year from date_key),
    is_crisis_period = (date_key between '2024-08-01' and '2024-12-31');

alter table dim_date add primary key (date_key);


-------------------------------------------------------------------------------
drop table if exists dim_city cascade;

create table dim_city as
select distinct city as city_std from staging_complaints_2023
union
select distinct city from staging_complaints_2024
union
select distinct city from staging_ola_sales_2024
union
select distinct city from staging_vahan_competitor_registrations
union
select distinct city from staging_service_centers;

alter table dim_city add column city_key serial primary key;
alter table dim_city add column state text;
alter table dim_city add column rto_code text;

-------------------------------------------------------------------------------


drop table if exists dim_oem cascade;

create table dim_oem as
select distinct oem
from staging_vahan_competitor_registrations
where oem is not null

union

select distinct oem
from staging_competitor_incidents
where oem is not null;

alter table dim_oem
add primary key (oem);


create table fact_vahan_registrations as
select oem, reg_date, city, registrations from staging_vahan_competitor_registrations;
alter table fact_vahan_registrations add foreign key (oem) references dim_oem(oem);


----------------------------------------------

drop table if exists dim_part cascade;
create table dim_part as
select distinct part_code, part_name from staging_spare_parts;
alter table dim_part add primary key (part_code);


create table fact_spare_parts as
select part_code, week_start as week, qty_consumed, stockout_days from staging_spare_parts;
alter table fact_spare_parts add foreign key (part_code) references dim_part(part_code);

-------------------------------------------------------

drop table if exists dim_service_center cascade;

create table dim_service_center as
select
    s.center_id,
    c.city_key,
    s.opened_date,
    s.capacity_jobs_per_day as capacity
from staging_service_centers s
join dim_city c on c.city_std = s.city;

alter table dim_service_center add primary key (center_id);
alter table dim_service_center add foreign key (city_key) references dim_city(city_key);



---------------------------------------------

select count(*) from dim_date;
select count(*) from dim_city;
select count(*) from dim_oem;
select count(*) from dim_part;
select count(*) from dim_service_center;

-------------------------------------------------

select * from staging_warranty

drop table if exists fact_warranty;

create table fact_warranty as
select w.claim_id,w.chassis_no,w.claim_date as date_key,w.component,w.claim_amount as claim_amount_inr 
from staging_warranty w 

select * from fact_warranty

alter table fact_warranty add primary key (claim_id)


drop table if exists fact_warranty;



select * from staging_master_id_map

select * from staging_ola_sales_2024

drop table if exists dim_vehicle_customer;
create table dim_vehicle_customer as
select m.chassis_no,m.customer_id, m.vehicle_reg_no, m.mobile_hash from staging_master_id_map m

---------------------------------------

--creating fact tables using staging tables 



create table staging_archive_ola_sales_2023
(
sale_date date,city text,model text,units_sold int ,avg_selling_price int 
)

drop table if exists staging_ola_sales_merged_2023
create table staging_ola_sales_merged_2023 as (
select o.sale_date, o.city, o.model, o.units_sold, o.avg_selling_price from staging_ola_sales_2023 o
union all
select s.sale_date, s.city, s.model, s.units_sold, s.avg_selling_price from staging_archive_ola_sales_2023 s
)


create table fact_sales_2023 as
select 
    row_number() over () as sale_id,
    dc.city_std,  
    s.sale_date,
    s.model,
    s.units_sold,
    s.avg_selling_price
from staging_ola_sales_merged_2023 s
join dim_city dc on s.city = dc.city_std;


create table fact_sales_2024 as
select 
    row_number() over () as sale_id,
    dc.city_std,  -- or city_key if you added a serial key
    s.sale_date,
    s.model,
    s.units_sold,
    s.avg_selling_price_inr
from staging_ola_sales_2024 s
join dim_city dc on s.city = dc.city_std;

select * from staging_ola_sales_2024

drop table if exists fact_sales;
create table fact_sales as (
select sale_id,city_std,sale_date,model,units_sold,avg_selling_price 
from fact_sales_2023
union all
select sale_id,city_std,sale_date,model,units_sold,avg_selling_price_inr as avg_selling_price
from fact_sales_2024
)

select * from fact_sales
select * from dim_vehicle_customer
select * from dim_service_center



select * from staging_complaints_2023
select * from staging_complaints_2024
alter table staging_complaints_2023
alter column tat_days type int
using nullif(trim(tat_days), '')::int;


drop table if exists fact_jobcards

drop table if exists staging_

drop table if exists fact_complaints cascade;
create table fact_complaints as
select * from staging_complaints_2023
union all
select * from staging_complaints_2024;
alter table fact_complaints add primary key (ticket_id);

select * from staging_jobcards
alter table staging_jobcards
rename column job_jobcard_id to jobcard_id;

alter table staging_jobcard
rename to staging_jobcards;


create table staging_complaints_2023 (
    ticket_id text,
    customer_id text,
    vehicle_reg_no text,
    city text,
    complaint_date date,
    channel text,
    complaint_text text,
    component_tag text,
    severity text,
    status text,
    resolution_date text,
    tat_days int,
    csat_score int,
    assigned_center_id text
);

select * from staging_complaints_2023
drop table if exists staging_complaints_2023;

create table staging_complaints_2023 (
    ticket_id text,
    customer_id text,
    vehicle_reg_no text,
    city text,
    complaint_date text,
    channel text,
    complaint_text text,
    component_tag text,
    severity text,
    status text,
    resolution_date text,
    tat_days text,
    csat_score text,
    assigned_center_id text
);

drop table if exists staging_complaints_2024;

create table staging_complaints_2024 (
    ticket_id text,
    customer_id text,
    vehicle_reg_no text,
    city text,
    complaint_date text,
    channel text,
    complaint_text text,
    component_tag text,
    severity text,
    status text,
    resolution_date text,
    tat_days text,
    csat_score text,
    assigned_center_id text
);


drop table if exists fact_complaints cascade;
create table fact_complaints as
select * from staging_complaints_2023
union all
select * from staging_complaints_2024;
alter table fact_complaints add primary key (ticket_id);

select count(*) from staging_complaints_2023 where ticket_id is null or ticket_id = '';
select count(*) from staging_complaints_2024 where ticket_id is null or ticket_id = '';
select * from staging_complaints_2023 where ticket_id is null or ticket_id = '';

delete from staging_complaints_2023 where ticket_id is null or ticket_id = '';

alter table staging_jobcards
add column mobile_hash text
drop table if exists staging_jobcards;
create table staging_jobcards 
(
    jobcard_id text, center_id text, chassis_no text, mobile_hash text,open_date date, close_date date, issue_category text,
    parts_replaced int, parts_cost_inr int, labour_cost_inr int, technician_id text, status text, linked_ticket_id text 
)
---------------------------------
--important note for fact_jobcards, it only exists for 2024
select * from fact_jobcards

drop table if exists fact_jobcards cascade;
create table fact_jobcards as
select * 
from staging_jobcards;
alter table fact_jobcards add primary key (jobcard_id);

select * from fact_jobcards

select * from staging_warranty

drop table staging_warranty

select * from fact_jobcards

create table fact_jobcards as
select jobcard_id,chassis_no,center_id,open_date,close_date,parts_cost_inr as parts_cost,
labour_cost_inr as labour_cost,linked_ticket_id
from staging_jobcards;
alter table fact_jobcards add primary key (jobcard_id);



select claim_id, count(*) from staging_warranty group by claim_id


select * from staging_warranty
drop table staging_warranty;

create table staging_warranty(
claim_id text,
chassis_no text,
vehicle_reg_no text,
claim_date date,
component text,
claim_amount int,
km_at_claim int,
approved_flag	text,
dealer_center_id text
);

alter table 


alter table staging_warranty
alter column claim_amount type numeric;

select * from fact_warranty
create table fact_warranty as
    select claim_id,chassis_no,claim_date,component,claim_amount as claim_amount_inr from staging_warranty;
alter table fact_warranty add primary key (claim_id);

select * from staging_master_id_map
drop table if exists dim_vehical_customer
create table dim_vehicle_customer (
    chassis_no primary key,
    customer_id,
	vehicle_reg_no,
    mobile_hash,
    model,
    city_key int references dim_city(city_key)
);

drop table if exists dim_vehicle_customer cascade;
create table dim_vehicle_customer as
select distinct chassis_no, customer_id, vehicle_reg_no, mobile_hash
from staging_master_id_map
where chassis_no is not null;


	create table dim_city as
select distinct on (combined.city_std)
    combined.city_std,
    service_state.state,
    vahan_rto.city as rto_code
from (
    select city as city_std from staging_ola_sales_2023
    union
    select city from staging_ola_sales_2024
    union
    select city from staging_archive_ola_sales_2023
    union
    select city from staging_complaints_2023
    union
    select city from staging_complaints_2024
    union
    select city from staging_service_centers
) combined
left join (
    select distinct city, state
    from staging_service_centers
) service_state
    on combined.city_std = service_state.city
left join (
    select distinct city
    from staging_vahan_competitor_registrations
) vahan_rto
    on combined.city_std = vahan_rto.city
where combined.city_std is not null
  and trim(combined.city_std) <> '';

alter table dim_city add primary key (city_std);
	

create table staging_ola_sales_merged_2023 as (
select o.sale_date, o.city, o.model, o.units_sold, o.avg_selling_price from staging_ola_sales_2023 o
union all
select s.sale_date, s.city, s.model, s.units_sold, s.avg_selling_price from staging_archive_ola_sales_2023 s
)
select * from dim_oem
select * from dim_city
select * from dim_date
select * from dim_service_center
select * from fact_vahan_registrations
select * from dim_part
select * from dim_vehicle_customer
select * from fact_spare_parts
select * from fact_sales
select * from fact_complaints
select * from fact_jobcards
select * from  dim_vehicle_customer

alter table dim_vehicle_customer add primary key (chassis_no);

-- fact_sales
select * from dim_city
alter table fact_sales add foreign key (city_std) references dim_city(city_std);

-- fact_complaints
alter table fact_complaints add foreign key (city) references dim_city(city_std);
alter table fact_complaints add foreign key (assigned_center_id) references dim_service_center(center_id);

-- fact_jobcards
alter table fact_jobcards add foreign key (chassis_no) references dim_vehicle_customer(chassis_no);
alter table fact_jobcards add foreign key (center_id) references dim_service_center(center_id);
alter table fact_jobcards add foreign key (linked_ticket_id) references fact_complaints(ticket_id);
select count(distinct chassis_no) as jobcard_chassis_not_in_map
from staging_jobcards j
where not exists (
    select 1 from dim_vehicle_customer d where d.chassis_no = j.chassis_no
);
insert into dim_vehicle_customer (chassis_no)
select distinct j.chassis_no
from staging_jobcards j
where j.chassis_no is not null
and not exists (
    select 1 from dim_vehicle_customer d where d.chassis_no = j.chassis_no
);

select count(distinct chassis_no) as warranty_chassis_not_in_map
from staging_warranty w
where not exists (
    select 1 from dim_vehicle_customer d where d.chassis_no = w.chassis_no
);
insert into dim_vehicle_customer (chassis_no)
select distinct w.chassis_no
from staging_warranty w
where w.chassis_no is not null
and not exists (
    select 1 from dim_vehicle_customer d where d.chassis_no = w.chassis_no
);

select * from staging_warranty

-- fact_warranty
alter table fact_warranty add foreign key (chassis_no) references dim_vehicle_customer(chassis_no);

-- fact_spare_parts
alter table fact_spare_parts add foreign key (part_code) references dim_part(part_code);

-- fact_vahan_registrations
alter table fact_vahan_registrations add foreign key (oem) references dim_oem(oem);
------------------------------------------------------------
----dql queries
---------------------------------------------------------------
-- Duplicates were already resolved upstream in Excel
--(priority rank + Remove Duplicates); 
--and deletes 0 rows on the cleaned staging data.
----------------------------------------
---2.monthly sales trend with mom growth using lag()
--Here we are considering the sales based on total units sols

select * from fact_sales

with monthly as (
    select EXTRACT(month from sale_date) as sale_month,EXTRACT(year from sale_date) as sale_year,
       sum(units_sold) as monthly_units
    from fact_sales 
    group by sale_month,sale_year
)
select
    sale_month,
    sale_year,
    monthly_units,
    lag(monthly_units) over (order by sale_month, sale_year) as prev_month_units,
    round(
        (monthly_units - lag(monthly_units) over (order by sale_year, sale_month))
        * 100.0
        / nullif(lag(monthly_units) over (order by sale_year, sale_month), 0),
        2
    ) as mom_growth_pct
from monthly
order by sale_year, sale_month;
----------------------------------------------------------------------------
---
--- city-wise complaints per 1,000 vehicles
--used this formula from brief
--complaints per 1,000 = monthly complaints ÷ cumulative vehicles × 1000

select * from fact_sales 
CREATE TABLE monthly_complaints AS
SELECT d.year, d.month, COUNT(*) AS complaints
FROM fact_complaints fc
JOIN dim_date d ON d.date_key = fc.complaint_date
GROUP BY d.year, d.month;

CREATE TABLE monthly_sales AS
SELECT d.year, d.month, SUM(fs.units_sold) AS vehicles_sold
FROM fact_sales fs
JOIN dim_date d ON d.date_key = fs.sale_date
GROUP BY d.year, d.month;

SELECT
    s.year, s.month, c.complaints,
    SUM(s.vehicles_sold) OVER (ORDER BY s.year, s.month) AS cumulative_vehicles,
    ROUND(c.complaints * 1000.0 / SUM(s.vehicles_sold) OVER (ORDER BY s.year, s.month), 2) AS complaints_per_1000
FROM monthly_sales s
JOIN monthly_complaints c ON c.year = s.year AND c.month = s.month
ORDER BY s.year, s.month;
select * from fact_complaints 
--monthly complaints ÷ cumulative vehicles × 1000
SELECT SUM(units_sold) FROM fact_sales;


select * from fact_complaints
select * from dim_city
select * from fact_sales
--------------------------------------------------------------------
--top 5 complaint components per quarter

select * from fact
with complaints as (
    select
        d.year,
        d.quarter,
        f.component_ta,
        count(*) as complaint_count
    from fact_complaints f
    join dim_date d
        on f.complaint_date = d.date_key
    group by d.year, d.quarter, f.component
),
ranked as (
    select
        year,
        quarter,
        component,
        complaint_count,
        row_number() over (
            partition by year, quarter
            order by complaint_count desc
        ) as rn
    from complaints
)
select
    year,
    quarter,
    component,
    complaint_count
from ranked
where rn <= 5
order by year, quarter, complaint_count desc;

-----------------------------------------------------
--centre-level average tat with rank()

with center as (
    select
        assigned_center_id,
        avg(tat_days) as avg_tat
    from fact_complaints
    where tat_days is not null
    group by assigned_center_id
)
select
    assigned_center_id,
    round(avg_tat, 1) as avg_tat,
    rank() over (order by avg_tat desc) as tat_rank
from center
order by tat_rank;

select * from fact_complaints
---------------------------------------------------
----------tickets whose linked job card is still open
select
    fc.ticket_id,
    fj.jobcard_id,
    fj.close_date
from fact_complaints fc
join fact_jobcards fj
    on fc.ticket_id = fj.linked_ticket_id
where fc.status in ('resolved', 'closed')
and fj.close_date is null;
-------------------------------------------------------

--warranty cost per component per month
select
    d.year,
    d.month,
    w.component,
    sum(w.claim_amount_inr) as total_warranty_cost
from fact_warranty w
join dim_date d
    on d.date_key = w.claim_date
group by d.year, d.month, w.component
order by d.year, d.month, w.component;

select * from fact_warranty

----------------------------------------------------

-- market share per oem per month from vahan;
--formula used,market share % = oem registrations ÷ total registrations (same period) × 100

select 
    extract(year from reg_date) as reg_year,
    extract(month from reg_date) as reg_month,
    oem,
    sum(registrations) as oem_monthly_registrations,
    sum(sum(registrations)) over (partition by extract(year from reg_date), extract(month from reg_date)) as total_monthly_registrations,
    round(
        sum(registrations) * 100.0 / sum(sum(registrations)) over (partition by extract(year from reg_date), extract(month from reg_date)),
        2
    ) as market_share_pct
from fact_vahan_registrations
group by extract(year from reg_date), extract(month from reg_date), oem
order by reg_year, reg_month, market_share_pct desc;
---------------------------------------------------
-- formula: % within 7 days = tickets with tat <= 7 ÷ total tickets × 100
% tickets resolved within 7 days, by month
select
    d.year,
    d.month,
    count(*) as total_tickets,
    sum(case when f.tat_days <= 7 then 1 else 0 end) as resolved_within_7d,
    round(
        sum(case when f.tat_days <= 7 then 1 else 0 end) * 100.0
        / count(*),
        1
    ) as pct_within_7d
from fact_complaints f
join dim_date d
    on f.complaint_date = d.date_key
where f.tat_days is not null
group by d.year, d.month
order by d.year, d.month;

select * from dim_date
select * from fact_complaints

-------------------------------------------------
--stockout weeks per part
-- formula: stockout weeks = weeks where stockout_days > 0

-- formula: stockout rate = stockout weeks ÷ total part-weeks × 100

select
    part_code,
    count(case when stockout_days > 0 then 1 end) as stockout_weeks,
    count(*) as total_weeks,
    round(
        count(case when stockout_days > 0 then 1 end) * 100.0
        / count(*),
        2
    ) as stockout_rate
from staging_spare_parts
group by part_code
order by stockout_rate desc;

----------------------------------------------
---escalation rate trend
-- formula: escalation rate = escalated tickets ÷ total tickets × 100

select
    d.year,
    d.month,
    count(*) as total_tickets,
    sum(case when f.status = 'escalated' then 1 else 0 end) as escalated,
    round(
        sum(case when f.status = 'escalated' then 1 else 0 end) * 100.0
        / count(*),
        2
    ) as escalation_rate
from fact_complaints f
join dim_date d
    on f.complaint_date = d.date_key
group by d.year, d.month
order by d.year, d.month;
-------------------------------------------------------------------
--csat vs tat band
-- formula: csat = average csat_score for resolved tickets

select
    case
        when tat_days <= 3 then '0-3 days'
        when tat_days <= 7 then '4-7 days'
        when tat_days <= 14 then '8-14 days'
        else '15+ days'
    end as tat_band,
    round(avg(csat_score), 2) as avg_csat,
    count(*) as ticket_count
from fact_complaints
where csat_score is not null
  and status in ('resolved', 'closed')
  and tat_days is not null
group by tat_band
order by tat_band;

----------------------------------------------
--self-join: repeat complaints on same vehicle within 30 days

select
    a.customer_id,
    a.ticket_id as first_ticket,
    b.ticket_id as repeat_ticket,
    a.complaint_date as first_date,
    b.complaint_date as repeat_date,
    b.complaint_date - a.complaint_date as days_apart
from fact_complaints a
join fact_complaints b
    on a.customer_id = b.customer_id
    and b.complaint_date > a.complaint_date
    and b.complaint_date <= a.complaint_date + 30
order by a.customer_id, a.complaint_date;
----------------------------------------------------------------

--DCL
--commands

create role analyst_readonly
with login password 'analyst123';

alter role service_ops password null;
alter role analyst_readonly password null;

grant select on
    fact_sales,
    fact_complaints,
    fact_jobcards,
    fact_warranty,
    dim_city,
    dim_date,
    dim_oem,
    dim_part,
    dim_service_center,
    dim_vehicle_customer
to analyst_readonly;


-- 2. create service-operations role
create role service_ops
with login password 'serviceops123';

grant select, update
on fact_complaints
to service_ops;


-- 3. demonstrate revoke
revoke update
on fact_complaints
from service_ops;

-------------------------------------------------------------
select claim_id, claim_amount_inr
from fact_warranty
limit 10;

create temp table test_warranty as
select claim_id, claim_amount_inr
from fact_warranty
where claim_id = 'wc-000001';

select * from test_warranty;

start transaction;

-- step 1: first adjustment
update test_warranty
set claim_amount_inr = claim_amount_inr - 5000
where claim_id = 'wc-000001';

savepoint before_reversal;

-- step 2: duplicate adjustment by mistake
update test_warranty
set claim_amount_inr = claim_amount_inr - 5000
where claim_id = 'wc-000001';

start transaction;

savepoint before_reversal;

-- mistaken duplicate adjustment
update test_warranty
set claim_amount_inr = claim_amount_inr - 5000
where claim_id = 'wc-000001';

-- check: should show ₹32,842
select * from test_warranty;

-- undo the duplicate adjustment
rollback to savepoint before_reversal;

-- check: should show ₹37,842
select * from test_warranty;

commit;

-----------------------------------------------------------------

--get your monthly aggregates out of sql first
with monthly_sales as (
    select
        extract(year from sale_date) as year,
        extract(month from sale_date) as month,
        sum(units_sold) as total_sales
    from fact_sales
    group by
        extract(year from sale_date),
        extract(month from sale_date)
),

monthly_complaints as (
    select
        extract(year from complaint_date) as year,
        extract(month from complaint_date) as month,
        count(*) as total_complaints,
        avg(tat_days) as avg_tat,
        avg(csat_score) as avg_csat
    from fact_complaints
    group by
        extract(year from complaint_date),
        extract(month from complaint_date)
)

select
    coalesce(ms.year, mc.year) as year,
    coalesce(ms.month, mc.month) as month,
    coalesce(ms.total_sales, 0) as total_sales,
    coalesce(mc.total_complaints, 0) as total_complaints,
    mc.avg_tat,
    mc.avg_csat

from monthly_sales ms

full outer join monthly_complaints mc
    on ms.year = mc.year
    and ms.month = mc.month

order by year, month;

select * from fact_sales

select * from fact_complaints
alter table fact_complaints
alter column tat_days type int
using nullif(tat_days, '')::int;

staging_complaints_2023
alter table fact_complaints

alter table fact_complaints
alter column complaint_date type date
using complaint_date::date;

select tat_days, pg_typeof(tat_days) from fact_complaints limit 5;

select csat_score, pg_typeof(csat_score) from fact_complaints limit 5;



alter table fact_complaints
alter column csat_score type int
using nullif(csat_score, '')::int;

alter table staging_complaints_2024
alter column complaint_date type text
using nullif(complaint_date, '')::date;

alter table staging_complaints_2023
alter column complaint_date type text
using nullif(complaint_date, '')::date;

select * from complaints


---------------------------------------------------------
---phase 3
--monthly sales & monthly complaints

select * from fact_sales

---------------------------------------------

--phase 3-

--metric 1: complaints per 1,000 vehicles = (monthly complaints ÷ cumulative vehicles on road) × 1,000
--metric 2: vehicles per active service centre = cumulative vehicles ÷ number of active centres that month

--cumulative vehicles on road — this is a running total of units sold, not just that month's sales.


--monthly units sold
select 
    extract(year from d.date_key) as year,
    extract(month from d.date_key) as month,
    coalesce(sum(fs.units_sold), 0) as monthly_units_sold
from dim_date d
left join fact_sales fs 
    on extract(year from fs.sale_date) = extract(year from d.date_key)
    and extract(month from fs.sale_date) = extract(month from d.date_key)
group by extract(year from d.date_key), extract(month from d.date_key)
order by year, month;

-------------------------------------------------------
--monthly complaint counts

select 
    extract(year from d.date_key) as year,
    extract(month from d.date_key) as month,
    count(fc.ticket_id) as monthly_complaints
from dim_date d
left join fact_complaints fc 
    on extract(year from fc.complaint_date) = extract(year from d.date_key)
    and extract(month from fc.complaint_date) = extract(month from d.date_key)
group by extract(year from d.date_key), extract(month from d.date_key)
order by year, month;

--------------------------

select * from dim_service_center
--servive centre count, joining dim_date so that we can compare opened_date to all dates from date calender and
--calulate active centers so for in need of opened date comparison we need to dim_date join 

select 
    extract(year from d.date_key) as year,
    extract(month from d.date_key) as month,
    count(sc.center_id) as active_centres
from dim_date d
left join dim_service_center sc on sc.opened_date <= d.date_key
group by extract(year from d.date_key), extract(month from d.date_key)
order by year, month;

----------------------------------
--cumulative vehicles (running total of monthly units sold) — needed for both metrics' denominator/
numerator base

select 
    extract(year from d.date_key) as year,
    extract(month from d.date_key) as month,
    coalesce(sum(fs.units_sold), 0) as monthly_units_sold,
    sum(coalesce(sum(fs.units_sold), 0)) over (order by extract(year from d.date_key), extract(month from d.date_key)) as cumulative_vehicles
from dim_date d
left join fact_sales fs 
    on extract(year from fs.sale_date) = extract(year from d.date_key)
    and extract(month from fs.sale_date) = extract(month from d.date_key)
group by extract(year from d.date_key), extract(month from d.date_key)
order by year, month;

-------------------------------------------------------------
--phase 3
--get daily sales before oct-2024
select 
    sale_date,
    sum(units_sold) as daily_units_sold,
    case when sale_date < '2024-10-01' then 'before' else 'after' end as period
from fact_sales
group by sale_date
order by sale_date;
-------------------------------------
--for lag comparison we need this data for monthly units sold, monthly complaints 

WITH s AS (
    SELECT d.year, d.month, SUM(fs.units_sold) AS monthly_units_sold
    FROM fact_sales fs
    JOIN dim_date d ON d.date_key = fs.sale_date
    GROUP BY d.year, d.month
),
c AS (
    SELECT d.year, d.month, COUNT(*) AS monthly_complaints
    FROM fact_complaints fc
    JOIN dim_date d ON d.date_key = fc.complaint_date
    GROUP BY d.year, d.month
)
SELECT s.year, s.month, s.monthly_units_sold, c.monthly_complaints
FROM s
JOIN c ON c.year = s.year AND c.month = s.month
ORDER BY s.year, s.month;


-----For a solid report plan, query is intended to have sales,complaints,csat,turnaround days, customer_satsisfaction,
--and stockput rate by parts

with sales as (
    select
        extract(year from sale_date) as year,
        extract(month from sale_date) as month,
        sum(units_sold) as sales
    from fact_sales
    group by
        extract(year from sale_date),
        extract(month from sale_date)
),

complaints as (
    select
        extract(year from complaint_date) as year,
        extract(month from complaint_date) as month,
        count(*) as complaints
    from fact_complaints
    group by
        extract(year from complaint_date),
        extract(month from complaint_date)
),

csat as (
    select
        extract(year from complaint_date) as year,
        extract(month from complaint_date) as month,
        round(avg(csat_score), 2) as csat
    from fact_complaints
    where csat_score is not null
    group by
        extract(year from complaint_date),
        extract(month from complaint_date)
),

tat as (
    select
        extract(year from complaint_date) as year,
        extract(month from complaint_date) as month,
        round(avg(tat_days), 2) as tat_days
    from fact_complaints
    where tat_days is not null
    group by
        extract(year from complaint_date),
        extract(month from complaint_date)
),

stockout as (
    select
        extract(year from week_start) as year,
        extract(month from week_start) as month,
        round(
            100.0 * count(*) filter (where stockout_days > 0) / count(*),
            2
        ) as stockout_rate
    from staging_spare_parts
    group by
        extract(year from week_start),
        extract(month from week_start)
)
select
    s.year,
    s.month,
    s.sales,
    c.complaints,
    cs.csat,
    st.stockout_rate,
	t.tat_days
from sales s
left join complaints c
    on s.year = c.year and s.month = c.month
left join csat cs
    on s.year = cs.year and s.month = cs.month
left join stockout st
    on s.year = st.year and s.month = st.month
	left join tat t
	on t.year = s.year and s.month = t.month
where s.year in (2023, 2024)
order by s.year, s.month;

alter role postgres with password '1610'; --- because of some reason the previosu passsword was not working so had to change
PGadmin password


select * from staging_competitor_incidents limit 20;
select oem, count(*) as incident_count, avg(resolution_days) as avg_resolution_days
from staging_competitor_incidents
group by oem;

------------------------------------------------------------
--Required for  analysis report PPT - Total Registraions in year 2024 per OEM
select
    oem, extract(year from reg_date),
    sum(registrations) as total_registrations
from fact_vahan_registrations
where extract(year from reg_date) = '2024' 
group by oem, extract(year from reg_date)
order by total_registrations;
-------------------------------------------------------------
--Required for  analysis report PPT - Total Registraions


select
    count(*) as rows,
    sum(registrations) as total_registrations
from fact_vahan_registrations;

-----------------------------------------------
--Required for  analysis report PPT - Count of incidents per OEM
select 
    oem,
    incident_type,
    count(*) as incident_count,
    avg(resolution_days) as avg_resolution_days
from staging_competitor_incidents
group by oem, incident_type
order by oem, incident_count desc;
-------------------------------------------------
--Required for  analysis report PPT - Market-share percent of year 2024 for all OEM
select
    oem,
    sum(registrations) as oem_2024_registrations,
    round(
        sum(registrations) * 100.0 / sum(sum(registrations)) over (),
        2
    ) as market_share_pct_2024
from fact_vahan_registrations
where extract(year from reg_date) = 2024
group by oem
order by market_share_pct_2024 desc;
select city_std from dim_city where city_std = 'Bhubaneswa'
UPDATE dim_city SET city_std = 'Bhubaneswar' WHERE city_std = 'Bhubaneswa';

UPDATE fact_sales SET city_std = 'Bhubaneswar' WHERE city_std = 'Bhubaneswa';
UPDATE fact_complaints SET city = 'Bhubaneswar' WHERE city_std = 'Bhubaneswa';

DELETE FROM dim_city WHERE city_std = 'Bhubaneswa';
UPDATE dim_city SET state = 'Odisha' WHERE city_std = 'Bhubaneswar';

SELECT * FROM dim_oem WHERE oem ILIKE '%ather%';


SELECT DISTINCT sale_date
FROM fact_sales
WHERE sale_date IS NULL
   OR sale_date NOT IN (SELECT date_key FROM dim_date)
ORDER BY 1;


   SELECT oem, LENGTH(oem) FROM dim_oem ORDER BY oem;