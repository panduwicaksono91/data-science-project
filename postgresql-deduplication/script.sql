create schema dedupe

create table dedupe.officers(
	id int primary key not null,
	last_name varchar(30),
	first_name varchar(30),
	address1 text,
	address2 text,
	city varchar(20),
	state varchar(20),
	zip varchar(20),
	title text,
	phone text,
	redaction_requested boolean
);

create table dedupe.officers_result(
	id int primary key not null,
	last_name varchar(30),
	first_name varchar(30),
	address1 text,
	address2 text,
	city varchar(20),
	state varchar(20),
	zip varchar(20),
	title text,
	phone text,
	redaction_requested boolean
);

drop table dedupe.officers;
drop table dedupe.officers_result;
drop table dedupe.tmp_id;
drop table dedupe.tmp_result;

\copy dedupe.officers from 'C:\Users\pandu.wicaksono91\Downloads\SQL Dataset\dedupe\officers.csv' delimiter ',' csv header;

select left(last_name,1) as init, last_name from dedupe.officers limit 15;

select lower(left(last_name,1)) as init, count(*) as tot
from dedupe.officers
group by lower(left(last_name,1))
order by tot desc;

select * from dedupe.officers where last_name ilike 'x%';

select count(*) from (
	select * from dedupe.officers where not (dedupe.officers.first_name is not null)
	) as S1;
	
select zip, count(*) as total
from dedupe.officers
group by zip
order by total desc;

create table dedupe.tmp_id(
	id int primary key
);

insert into dedupe.tmp_id(
	select id from dedupe.officers
);

create table dedupe.tmp_result(
	id_first int not null,
	id_second int not null,
	primary key (id_first, id_second)
);

select 	S1.id, S2.id,
		S1.last_name, S2.last_name, similarity(S1.last_name,S2.last_name),
		S1.first_name, S2.first_name, similarity(S1.first_name,S2.first_name),
		S1.address1, S2.address1,similarity(S1.address1,S2.address1)
from 
(select * from dedupe.officers where last_name ilike 'a%') as S1 cross join
(select * from dedupe.officers where last_name ilike 'a%') as S2
where S1.id < S2.id;

insert into dedupe.tmp_result(id_first,id_second)
(
select 	S1.id, S2.id
from 
	(select * from dedupe.officers where last_name ilike 'z%') as S1 cross join
	(select * from dedupe.officers where last_name ilike 'z%') as S2
where
	similarity(S1.last_name,S2.last_name) > 0.90 and
	similarity(S1.first_name,S2.first_name) > 0.90 and
	similarity(S1.address1,S2.address1) >0.70 and
	S1.id < S2.id
order by S1.id desc
);

-- select * from dedupe.officers where last_name ilike 'x%';

delete from dedupe.tmp_id where id in
(
	select id_second 
	from dedupe.tmp_result
);

insert into dedupe.officers_result 
(
	select * from dedupe.officers where id in 
	(
		select id from dedupe.tmp_id
	)
);

\copy dedupe.officers_result to 'C:\Users\pandu.wicaksono91\Downloads\SQL Dataset\dedupe\officers_result.csv' delimiter ',' csv header;
