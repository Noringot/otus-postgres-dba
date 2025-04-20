# Настройка PostgreSQL

- PostgreSQL 17
- Debian 12.9
- CPU Cores: 3
- RAM memory: 8 GB

## Первое тестирование

Запускаем нагрузочное тестирование на параметрах по умолчанию, для дальнейшего ориентира

```shell
vbox:~$ sudo -u postgres pgbench  -c 90 -j 6 -P 10 -T 30 test
pgbench (17.4 (Debian 17.4-1.pgdg120+2))
starting vacuum...end.
progress: 10.0 s, 578.0 tps, lat 152.328 ms stddev 136.183, 0 failed
progress: 20.0 s, 589.9 tps, lat 152.336 ms stddev 132.295, 0 failed
progress: 30.0 s, 576.4 tps, lat 155.874 ms stddev 144.190, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 90
number of threads: 6
maximum number of tries: 1
duration: 30 s
number of transactions actually processed: 17532
number of failed transactions: 0 (0.000%)
latency average = 153.918 ms
latency stddev = 137.769 ms
initial connection time = 92.588 ms
tps = 583.198514 (without initial connection time)
```

При стандартной настройке, которая задается при установке, pgbench показывает что значение tps равно ~583

## Тюнинг

Воспользовавшись сервисом для тюнинга, настроил конфиг для системы, также увеличил work_mem до 32МБ, shared_buffers до 50% от общей ОЗУ. Все измененные параметры в Приложении №1

```shell
vbox:~$ sudo -u postgres pgbench  -c 90 -j 6 -P 10 -T 60 test
pgbench (17.4 (Debian 17.4-1.pgdg120+2))
starting vacuum...end.
progress: 10.0 s, 592.4 tps, lat 148.275 ms stddev 124.917, 0 failed
progress: 20.0 s, 603.1 tps, lat 149.313 ms stddev 143.385, 0 failed
progress: 30.0 s, 605.2 tps, lat 148.678 ms stddev 135.927, 0 failed
progress: 40.0 s, 600.2 tps, lat 150.347 ms stddev 136.553, 0 failed
progress: 50.0 s, 606.2 tps, lat 148.236 ms stddev 131.456, 0 failed
progress: 60.0 s, 605.9 tps, lat 148.577 ms stddev 133.812, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 90
number of threads: 6
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 36220
number of failed transactions: 0 (0.000%)
latency average = 149.038 ms
latency stddev = 134.514 ms
initial connection time = 94.737 ms
tps = 603.157250 (without initial connection time)
```

### №1. Листинг файла postgresql.auto.conf

```shell
# DB Version: 17
# OS Type: linux
# DB Type: oltp
# Total Memory (RAM): 8 GB
# CPUs num: 3
# Connections num: 100
# Data Storage: ssd

listen_addresses = '*'
max_parallel_workers_per_gather = '2'
max_worker_processes = '12'
max_connections = '100'
effective_cache_size = '6GB'
maintenance_work_mem = '512MB'
checkpoint_completion_target = '0.9'
wal_buffers = '16MB'
default_statistics_target = '100'
random_page_cost = '1.1'
effective_io_concurrency = '200'
huge_pages = 'off'
min_wal_size = '2GB'
max_wal_size = '8GB'
work_mem = '32MB'
shared_buffers = '6GB'
```