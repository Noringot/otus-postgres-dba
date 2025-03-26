# Физический уровень PostgreSQL

- Программа для работы с виртуальнымии машинами - Oracle Virtual Box
- ОС Debian 12.9
- Версия postgres 17
- vbox=> команды исполняются в среде Linux
- psql=> команды исполняются в среде psql

## Подготовка к переносу
1. Проверяем что кластер запущен

<pre><code>vbox=> pg_lsclusters

Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 online postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
</code></pre>

2. Создаем тестовую таблицу, заполняем данными

<pre><code>vbox=> sudo -u postgres psql

psql=> create table test(id int);
CREATE TABLE

psql=> insert into test (id) select generate_series(1, 4);
INSERT 0 4

psql=> select * from test;
 id
----
  1
  2
  3
  4
(4 rows)
</code></pre>

3. Останавливаем кластер

<pre><code>psql=> \q
vbox=> pg_ctlcluster 17 main stop
vbox=> pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
17  main    5432 down   postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log
</code></pre>

## Монтируем новый диск для ВМ
1. Создан и прикреплен новый диск к виртуальной машине (OtusDebian_1.vdi)
2. С помощью утилиты "parted" был размечен и смонтирован новый диск (/dev/sda1)
3. Проверяем, что после перезагрузки ВМ диск подключен

<pre><code>vbox=> df -h -x tmpfs
Filesystem      Size  Used Avail Use% Mounted on
udev            3.9G     0  3.9G   0% /dev
/dev/sda1        19G  8.0G  9.7G  46% /
/dev/sdb1       9.8G   24K  9.3G   1% /mnt/data
</code></pre>

## Перенос и запуск кластера между дисками
1. Переносим содержимое кластера

<pre><code>vbox=> mv /var/lib/postgresql/17 /mnt/data
vbox=> ls -la /mnt/data/17/main
total 88
drwx------ 19 postgres postgres 4096 Mar 26 01:52 .
drwx------  3 postgres postgres 4096 Mar 26 00:50 ..
drwx------  5 postgres postgres 4096 Feb 23 12:59 base
drwx------  2 postgres postgres 4096 Mar 26 01:45 global
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_commit_ts
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_dynshmem
drwx------  4 postgres postgres 4096 Mar 26 01:52 pg_logical
drwx------  4 postgres postgres 4096 Feb 23 12:59 pg_multixact
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_notify
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_replslot
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_serial
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_snapshots
drwx------  2 postgres postgres 4096 Mar 26 01:52 pg_stat
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_stat_tmp
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_subtrans
drwx------  2 postgres postgres 4096 Mar 25 23:58 pg_tblspc
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_twophase
-rwx------  1 postgres postgres    3 Feb 23 12:59 PG_VERSION
drwx------  4 postgres postgres 4096 Feb 23 12:59 pg_wal
drwx------  2 postgres postgres 4096 Feb 23 12:59 pg_xact
-rwx------  1 postgres postgres   88 Feb 23 12:59 postgresql.auto.conf
-rwx------  1 postgres postgres  130 Mar 26 01:45 postmaster.opts
</code></pre>

2. Пытаемся запустить кластер и получаем сообщение об ошибке, что такой кластер не найден или не доступен. Ошибка произошла, потому что в конфигурационных файлах, которые лежат отдельно от физического расположения самого кластера, указана старая директория $PGDATA

<pre><code>vbox=> pg_ctlcluster 17 main start
Error: /var/lib/postgresql/17/main is not accessible or does not exist
 </code></pre>

3. Находим конфигурационный файл *postgresql.conf*, меняем параметр *data_directory* на актуальный путь

<pre><code>vbox=> vi /etc/postgresql/17/main/postgresql.conf

# data_directory = '/var/lib/postgresql/17/main' - old value
data_directory = '/mnt/data/17/main'            # use data in another directory
</code></pre>

4. Заново пытаемся запустить кластер

<pre><code>vbox=> pg_ctlcluster 17 main start
vbox=> pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
17  main    5432 online postgres /mnt/data/17/main /var/log/postgresql/postgresql-17-main.log
</code></pre>

5. Проверяем содержимое тестовой таблицы

<pre><code>vbox=> sudo -u postgres psql

psql=> select * from test;
 id
----
  1
  2
  3
  4
(4 rows)
</code></pre>

## Перенос и запуск кластера между виртуальными машинами

1. Создаем новую ВМ, устанавливаем на нее Postgres 17
2. На "старой" машине переименуем (вместо удаления) каталог */var/lib/postgres*

<pre><code>vbox2=> pg_ctlcluster 17 main stop
vbox2=> systemctl status postgresql
vbox2=> mv /var/lib/postgres /var/lib/_postgres
</code></pre>

3. Останавливаем "старую" машину
4. Привязываем существующий диск (OtusDebian_1.vdi) к новосозданной ВМ
5. После запуска монтируем новый диск в нашу ВМ, определять и размечать диск не нужно
6. После установки Postgres сразу запущен кластер, остановим его, и изменим $PGDATA на содержимое монтированного диска с данными с другой ВМ

<pre><code>vbox2=> pg_lsclusters
Ver Cluster Port Status   Owner    Data directory              Log file
17  main    5432 online   postgres /var/lib/postgresql/17/main /var/log/postgresql/postgresql-17-main.log

vbox2=> pg_ctlcluster 17 main stop
vbox2=> vi /etc/postgresql/17/main/postgresql.conf
# data_directory = '/var/lib/postgresql/17/main' - old value
data_directory = '/mnt/data/17/main'            # use data in another directory
</code></pre>

7. После изменения пути, попробуем запустить кластер

<pre><code>vbox2=> pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
Missing argument in printf at /usr/bin/pg_lsclusters line 127
17  main    5432 down   postgres /mnt/data/17/main /var/log/postgresql/postgresql-17-main.log

vbox2=> pg_ctlcluster 17 main start
Error: The cluster is owned by ser id 113 which does not exist
</code></pre>

Получаем ошибку, что пользователя, который является владельцем файлов в _/mnt/data/*_, не существует. Скорее всего из-за того что в обеих машинах, есть одинаковый пользователь _postgres_, но уникальный id присвоенный им отличается на разных машинах

8. По новой присваем владение файлами для юзера _postgres_

<pre><code>vbox2=> sudo chown -R postgres:postgres /mnt/data
</code></pre>

9. Запускаем кластер, уже без ошибок

<pre><code>vbox2=> pg_ctlcluster 17 main start
vbox2=> pg_lsclusters
Ver Cluster Port Status Owner    Data directory    Log file
17  main    5432 online postgres /mnt/data/17/main /var/log/postgresql/postgresql-17-main.log
</code></pre>

10. Проверяем, что данные никуда не пропали

<pre><code>vbox2=> sudo -u postgres psql

psql2=> select * from test;
 id
----
  1
  2
  3
  4
(4 rows)
</code></pre>

## Итог

Научились немного работать с конфигурацией кластера постгреса, безопасно "замораживать" сам кластер и переносить на другое дисковое пространство без повреждения данных