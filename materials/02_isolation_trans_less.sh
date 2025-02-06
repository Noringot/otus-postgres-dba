https://cloud.google.com/sdk/docs/install#deb

gcloud auth login

Даллее проходим по первой предложенной ссылке и логинимся под тем пользователем у которого есть платежный аккаунт GC

Теперь можем устанавливать нашу ВМ

gcloud beta compute --project=celtic-house-266612 instances create postgres2 --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres2 --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any


Для того чтобы удлаить дистанционно нашу ВМ, нам необходимо добавить наш проект в конфиг CLI
gcloud config set project celtic-house-266612 

Теперь можем удалить нашу ВМ

gcloud compute instances delete postgres

ssh-keygen -t rsa -b 2048

ssh -i ~/.ssh/gc_key kimu-dev@34.171.5.81



# Virtual Machines (Compute Cloud) https://cloud.yandex.ru/docs/free-trial/

Создание виртуальной машины:
https://cloud.yandex.ru/docs/compute/quickstart/quick-create-linux

name vm: otus-db-pg-vm-1

Создать сеть:
Каталог: default
Имя: otus-vm-db-pg-net-1

Доступ
username: otus

Сгенерировать ssh-key:
bash
cd ~
cd .ssh
ssh-keygen -t rsa -b 2048
name ssh-key: yc_key
chmod 600 ~/.ssh/yc_key.pub
ls -lh ~/.ssh/
cat ~/.ssh/yc_key.pub # в Windows C:\Users\<имя_пользователя>\.ssh\yc_key.pub

Подключение к VM:
https://cloud.yandex.ru/docs/compute/operations/vm-connect/ssh


ssh -i ~/.ssh/yc_key otus@158.160.137.238 # в Windows ssh -i <путь_к_ключу/имя_файла_ключа> <имя_пользователя>@<публичный_IP-адрес_виртуальной_машины>

# Установка Postgres:
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15

pg_lsclusters

sudo -u postgres psql
\l

\q
sudo apt remove postgresql-15


-- Создаем сетевую инфраструктуру и саму VM:
yc vpc network create --name otus-net --description "otus-net" && \
yc vpc subnet create --name otus-subnet --range 192.168.0.0/24 --network-name otus-net --description "otus-subnet" && \
yc compute instance create --name otus-vm --hostname otus-vm --cores 2 --memory 4 --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 --ssh-key ~/.ssh/yc_key.pub 

-- Подключимся к VM:
vm_ip_address=$(yc compute instance show --name otus-vm | grep -E ' +address' | tail -n 1 | awk '{print $2}') && ssh -o StrictHostKeyChecking=no -i ~/.ssh/yc_key yc-user@$vm_ip_address 

-- Установим PostgreSQL:
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 

pg_lsclusters

sudo nano /etc/postgresql/14/main/postgresql.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf

sudo -u postgres psql
alter user postgres password 'postgres';

sudo pg_ctlcluster 14 main restart

yc compute instances list - 51.250.64.231

yc compute instance delete otus-vm && yc vpc subnet delete otus-subnet && yc vpc network delete otus-net

\set AUTOCOMMIT off

begin
commit
rollback # Отката изменений

