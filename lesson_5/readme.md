# Логический уровень PostgreSQL
- Версия PostgreSQL 17
- db_name(user_name)=# - команды в среде psql. Если не указан _user_name_, значит команды выполены под пользователем _postgres_
## Работа с базами данных, пользователями и правами

- В этом уроке научимся работать с базами данных, пользователями и правами

1. Зайдем в cluster под пользователем _postgres_ создадим БД _testdb_ и зайдем в нее

<pre><code>postgres=# create database testdb;
CREATE DATABASE
postgres=# \c testdb;
You are now connected to database "testdb" as user "postgres".
testdb=#
</code></pre>
2. Создаем новую схему в этой базе данных

<pre><code>testdb=# create schema testnm;
CREATE SCHEMA
</code></pre>
3. Создадим таблицу _t1_ с одной колонкой и вставим одну запись  

<pre><code>testdb=# create table t1 (c1 int);
CREATE TABLE
testdb=# insert into t1 (c1) values (1);
INSERT 0 1
testdb=#
</code></pre>
4. Создадим роль _readonly_ и добавим привелегии на подключение к БД _testdb_, использование схему _testnm_ и чтение всех таблиц из этой схемы

<pre><code>testdb=# create role readonly;
CREATE ROLE
testdb=# grant connect on database testdb to readonly;
GRANT
testdb=# grant usage on schema testnm to readonly;
GRANT
testdb=# grant select on all tables in schema testnm to readonly;
GRANT
</code></pre>
5. Создадим пользователя _testread_ и расшарим ему роль _readonly_ 

<pre><code>testdb=# create user testread with password 'test123';
CREATE ROLE
testdb=# grant readonly to testread;
GRANT ROLE
</code></pre>
6. Подключимся новоиспеченным пользователем и попробуем прочитать данные из таблицы _t1_

<pre><code>~ psql -U testread -d testdb
psql (17.4)
Type "help" for help.
testdb(testread)=> select * from t1;
ERROR:  permission denied for table t1
</pre></code>

Получаем ошибку, отсутствуют права на чтение этой таблицы. Кажется странным, учитывая что мы выдали права на чтение для целой схемы. Если воспользоваться мета-командой \dt, чтобы вывести список отношений, которые существуют в нашей БД, увидим следующее

<pre><code>testdb(testread)=> \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | t1   | table | postgres
(1 row)
</code></pre>

При создании таблицы мы явно не указали схему и таблица была создана в схеме по умолчанию, а именно в схеме _public_. Доступ на использование этой схемы для роли _readonly_, а соответственно и для пользователя _testread_ отсутствует.  
Избежать этого можно двумя путями, которые известны мне на данный момент. Во-первых, явно указать схему при создании таблицы _"create table schema_name.table_name"_. Во-вторых, можно изменить переменную _search_path_ и перед схемой _public_ указать нашу новую схему.

7. Вернемся под пользователя _postgres_ и пересоздадим таблицу _t1_, только уже в схеме _testnm_

<pre><code>testdb=# drop table t1;
DROP TABLE
testdb=# \dt
Did not find any relations.
testdb=# create table testnm.t1(c1 int);
CREATE TABLE
testdb=# insert into testnm.t1 (c1) values (1);
INSERT 0 1
</code></pre>

8. Но даже сейчас вновь получим ошибку доступа к таблице

<pre><code>testdb(testread)=> select * from testnm.t1;
ERROR:  permission denied for table t1
</code></pre>

Все дело в том что в 4-м пункте мы определили права доступа для объектов существующих на тот момент в схеме, что означает, что для новых объектов, которые будут или были добавлены после этого момента не распространяются эти права. Если повторить команду на предоставление чтения всех таблиц из схемы _testnm_, и просмотрим существующие права, увидим что у readonly есть право чтения на таблицу _t1_

<pre><code>testdb=# grant select on all tables in schema testnm to readonly;
GRANT
testdb=# \dp testnm.*;
                                 Access privileges
 Schema | Name | Type  |     Access privileges      | Column privileges | Policies
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
(1 row)
</code></pre>

Создадим еще одну таблицу в этой схеме, повторим команду \dp 

<pre><code>testdb=# create table testnm.t2(c2 integer);
CREATE TABLE
testdb=# \dp testnm.*;
                                 Access privileges
 Schema | Name | Type  |     Access privileges      | Column privileges | Policies
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
 testnm | t2   | table |                            |                   |
(2 rows)
</code></pre>

Видим что доступа на чтение из таблицы _t2_ по умолчанию нет. Для этого можно воспользоватьтся командой _ALTER DEFAULT PRIVILEGES_, которая определяет права по умолчанию в схеме для объектов, которые будут создаваться в будущем.

9. Теперь, удаляем существующие таблицы из схемы _testnm_. Поскольку при назначении прав по умолчанию они будут применены только к объектам, которые будут созданы в будущем, сначала назначаем эти права, затем создаем таблицы t1 и t2, затем просмотрим существующие права для пользователя _readonly_

<pre><code>testdb=# alter default privileges in schema testnm grant select on tables to readonly;
ALTER DEFAULT PRIVILEGES
testdb=# drop table testnm.t1;
DROP TABLE
testdb=# drop table testnm.t2;
DROP TABLE
testdb=# \dp testnm.*;
                            Access privileges
 Schema | Name | Type | Access privileges | Column privileges | Policies
--------+------+------+-------------------+-------------------+----------
(0 rows)

testdb=# create table testnm.t1 (c1 int);
CREATE TABLE
testdb=# create table testnm.t2 (c2 int);
CREATE TABLE
testdb=# \dp testnm.*;
                                 Access privileges
 Schema | Name | Type  |     Access privileges      | Column privileges | Policies
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
 testnm | t2   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
(2 rows)
</code></pre>

Теперь видим, что мы определили права один раз на чтение для роли _readonly_ и они автоматически были определены для таблиц созданных в этой схеме.

10. Для того чтобы удостовериться заполним данными эти таблицы и попробуем прочитать из под пользователя _testread_

<pre><code>testdb(postgres)=# insert into testnm.t1 (c1) values (1);
INSERT 0 1
testdb(postgres)=# insert into testnm.t2 (c2) values (2);
INSERT 0 1
testdb(testread)=> select * from testnm.t1;
 c1
----
  1
(1 row)

testdb(testread)=> select * from testnm.t2;
 c2
----
  2
(1 row)

</code></pre>

У этой команды есть ограничение, с помощью нее можно назначить права, которые добавляются к глобальным и отозвать только их.

## Особенности "ALTER DEFAULT PRIVILEGES"

Если не указан параметр _[ FOR { ROLE | USER } ]_, то определяемые права по умолчанию, будут распространяться на объекты созданные пользователем, который выполнил эту команду.

Проверим следующим образом, создадим нового пользователя, расшарим ему роль _readonly_, также даем возможность выполнять _CREATE_ в схеме _testnm_.

<pre><code>testdb(postgres)=# create user testuser with password '1234';
CREATE ROLE
testdb(postgres)=# grant readonly to testuser;
GRANT ROLE
testdb(postgres)=# grant create on schema testnm to testuser;
GRANT
</code></pre>

Дальше создаем под пользователем _postgres_ и под пользователем _testuser_ таблицы. Затем проверим назначенные права

<pre><code>testdb(postgres)=> create table testnm.t3 (c3 int);
CREATE TABLE
</code></pre>
<pre><code>~ psql -U testuser -d testdb
psql (17.4)
Type "help" for help.

testdb(testuser)=> create table testnm.t4 (c4 int);
CREATE TABLE
</code></pre>

<pre><code>testdb(postgres)=# \dp testnm.*
                                 Access privileges
 Schema | Name | Type  |     Access privileges      | Column privileges | Policies
--------+------+-------+----------------------------+-------------------+----------
 testnm | t1   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
 testnm | t2   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
 testnm | t3   | table | postgres=arwdDxtm/postgres+|                   |
        |      |       | readonly=r/postgres        |                   |
 testnm | t4   | table |                            |                   |
(4 rows)
</code></pre>

Видим, что права, по умолчанию, определены только для объекта, который был создан пользователем _postgres_

## Заключение
В этом задании познакомились с командами для создания новых пользователей/ролей и также научились определять права для этих ролей. Немного углубились в особенности работы команд для предоставления прав, также поработали немного со схемами
