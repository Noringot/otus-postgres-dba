# SQL и реляционные СУБД. Введение в PostgreSQL
## Работа с уровнями изоляции транзакции в PostgreSQL

- В этом уроке познакомимся с уровнями изоляции РСУБД для осуществления согласованности данных. Будет расмотрено два уровня изоляции: Read Commited и Repeatable Read

1. Создаем таблицу  
<pre><code>create table persons(  
    id serial,  
    first_name text,   
    second_name text  
);
</code></pre>

2. Заполняем данными  
<pre><code>insert into persons(first_name, second_name)  
    values('ivan', 'ivanov'),  
    values('petr', 'petrov');  
commit;
</code></pre>

Получилась таблица **persons**
<pre><code>=> select * from persons;

id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
</code></pre>

### Уровни изоляции. Read Commited
В первой транзакции вставляем новую запись
<pre><code>=> begin;
=> insert into persons (first_name, second_name) values ('sergey', 'sergeev');
</code></pre>
Во второй транзакции пытаемся прочитать данные из таблицы и видим только две строчки, новая строчка не попала в выборку, т.к. на этом уровне изоляции избегаем возникновения аномалии "грязного чтения". То есть только если параллельная (первая) транзакция зафиксирует свои изменения, они будут отображаться в текущей транзакции (второй).
<pre><code>=>begin;
=> select * from persons;

 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
</code></pre>
Зафиксируем изменения первой транзакции  
`=> commit;`  
Теперь если прочитаем данные из таблицы во второй транзакции, увидим новую запись
<pre><code>=> select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)

=>commit;
</code></pre>

### Уровни изоляции. Repeatable Read

Начнем новую транзакцию, добавим новую запись в таблицу
<pre><code>=> begin isolation level repeatable read;
=> insert into persons (first_name, second_name) values ('sveta', 'svetova');
</code></pre>
Также запустим вторую транзакцию, запросим данные из таблицы и получим такой же результат как и при read commited, т.к. последующие уровни избавляют от аномалий предыдущих уровней.
<pre><code>=>begin isolation level repeatable read;
=> select * from persons;

 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
</code></pre>

Однако, если мы зафиксируем изменения первой транзакции
<pre><code>=> commit;
select * from persons;

 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
  4 | sveta      | svetova
(4 rows)
</code></pre>

Во второй, не завершенной транзакции, изменения будут по-прежнему отсутствовать. И появятся, если завершить текущую и начать новую транзакцию.
<pre><code>=> select * from persons;
 id | first_name | second_name
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
  3 | sergey     | sergeev
(3 rows)
</code></pre>

Как итог, влияние параллельно выполняющихся транзакций друг на друга различно, при различных уровнях изоляции.

