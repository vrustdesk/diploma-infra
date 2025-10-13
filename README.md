# Diploma Infrastructure (Yandex Cloud)

Отказоустойчивая инфраструктура сайта: **Terraform + Ansible**, мониторинг (**Zabbix**), логи (**Filebeat → Elasticsearch + Kibana**), бэкапы (**snapshots**).  
Все секреты (токены/ключи) **не хранятся в git** — задаются через переменные окружения или `terraform.tfvars`.

---

## Архитектура

- **2× Nginx web** (приватные ВМ, разные зоны)
- **Application Load Balancer** (публичный :80, health-check `/`)
- **Bastion** (публичный SSH jump)
- **Elasticsearch** (приватная ВМ) + **Kibana** (публичная)
- **Zabbix server** (публичная UI) + **Zabbix agent** на всех ВМ
- **1× VPC**: публичная и приватные подсети, **NAT gateway**, **Security Groups**
- **Snapshots**: ежедневно, хранение 7 дней

```mermaid
flowchart LR
  internet((Internet)) --> ALB[YC ALB :80]

  subgraph Public Subnet
    Bastion[(Bastion SSH)]
    Kibana[(Kibana UI)]
    Zabbix[(Zabbix UI)]
  end

  subgraph Private Subnet
    webA(Web A - nginx)
    webB(Web B - nginx)
    ES[(Elasticsearch)]
  end

  ALB -->|HTTP| webA
  ALB -->|HTTP| webB

  %% Логи с вебов в Elasticsearch
  webA -- Filebeat logs --> ES
  webB -- Filebeat logs --> ES
  ```
Что в репозитории
Terraform — описывает всю инфраструктуру (VPC, subnets, NAT/RT, SG, ALB, ВМ).

Подсети — ресурсами с for_each (см. vpc.tf).

Web ВМ — с for_each из var.web_nodes (см. compute_web.tf).

ALB Target Group — dynamic "target" (см. alb.tf), backend group — target_group_ids.

Ansible — роли доводят сервера до рабочего состояния:

nginx, zabbix_agent, elasticsearch, kibana, filebeat (+ handlers, templates).

Инвентори использует FQDN вида *.ru-central1.internal и ProxyJump через bastion.

Быстрый старт
0) Предпосылки
Bastion с доступом в интернет.

Установлены Terraform (1.3+) и Ansible.

Публичный SSH ключ в ~/.ssh/id_ed25519.pub (или используйте свой путь).

1) Аутентификация в Yandex Cloud
Вариант A — токен:

bash
Copy code
export YC_TOKEN='<ваш_токен>'
export TF_VAR_yc_token="$YC_TOKEN"
# В provider уже есть строка: token = var.yc_token
Вариант B — ключ сервисного аккаунта:

bash
Copy code
mkdir -p ~/.yc
nano ~/.yc/sa.json   # вставьте JSON ключ

export TF_VAR_sa_key_file="/home/ubuntu/.yc/sa.json"
# В provider уже есть строка: service_account_key_file = var.sa_key_file
2) Заполнить terraform.tfvars
Минимальный пример (замените значениями вашего облака/образа/ключа):

hcl
Copy code
cloud_id  = "b1g........................"
folder_id = "b1g........................"
zone_a    = "ru-central1-a"
zone_b    = "ru-central1-b"

ssh_pub_key = "ssh-ed25519 AAAA... user@host"
image_id    = "fd8jf9qa6kj7nhat329h"   # Ubuntu 22.04
preemptible = true
snapshot_retention_days = 7

# --- сеть и подсети управляются Terraform ---
subnets = {
  public_d  = { zone = "ru-central1-d", cidr = ["10.128.0.0/24"] }
  private_a = { zone = "ru-central1-a", cidr = ["10.129.0.0/24"] }
  private_b = { zone = "ru-central1-b", cidr = ["10.130.0.0/24"] }
}

# --- веб-инстансы создаются в цикле ---
web_nodes = {
  "web-a" = { zone = "ru-central1-a", subnet = "private_a" }
  "web-b" = { zone = "ru-central1-b", subnet = "private_b" }
}
3) Terraform
bash
Copy code
terraform fmt
terraform init -upgrade
terraform validate
terraform plan -no-color -var-file=./terraform.tfvars -input=false | tee docs/terraform_plan.txt
# для скриншота:
tail -n 60 docs/terraform_plan.txt

# При необходимости (если готовы применять):
# terraform apply -var-file=./terraform.tfvars
4) Ansible
Инвентори использует FQDN *.ru-central1.internal и ProxyJump через bastion (см. ansible/hosts.ini).

bash
Copy code
cd ansible
ANSIBLE_NOCOLOR=1 ANSIBLE_HOST_KEY_CHECKING=False \
ansible all -m ping -i hosts.ini -u ubuntu | tee ../docs/ansible_ping.txt
tail -n 30 ../docs/ansible_ping.txt

ANSIBLE_NOCOLOR=1 ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook -i hosts.ini site.yml | tee ../docs/ansible_apply.txt
tail -n 60 ../docs/ansible_apply.txt
Скриншоты / пруфы
Все изображения в docs/screenshots/, а текстовые логи — в docs/*.txt.

Terraform: terraform-plan.png (хвост docs/terraform_plan.txt)

Ansible: ansible-ping.png, ansible-apply.png

YC объекты:

yc-vpc.png, yc-subnets.png, yc-nat.png, yc-security-groups.png, yc-vms.png

ALB: yc-alb.png (LB/Listener/HTTP router), alb-healthchecks.png

Веб: curl-80.png (ответ сайта через ALB)

Zabbix: zabbix-hosts.png, zabbix-dashboards.png

ELK: elastic-cluster-health.png, kibana-discover.png, kibana-index-pattern.png

Snapshots: snapshots-policy.png

Безопасность
Секреты не коммитятся: токены/ключи — только через переменные окружения или локальные файлы (~/.yc/sa.json).

Security Groups ограничивают доступ: web — только от SG ALB; агенты Zabbix — только от Zabbix; ES — только из приватных.

Веб-ВМ без внешних IP (доступ по SSH только через bastion).

Решения и компромиссы
Минимальные ВМ: 2 vCPU (20% Ice Lake), 2–4 GB RAM, 10 GB HDD, прерываемые (перед сдачей переведены в постоянные).

Исходящий интернет для приватных ВМ через NAT.

Логи: Filebeat (web) → Elasticsearch; UI — Kibana.

Мониторинг: Zabbix по принципу USE (CPU/RAM/Disk/Net) + web-сценарий /.

Бэкапы: snapshot-сchedule ежедневно, retention 7 дней.

Доработки по ревью
VPC/подсети: создаются ресурсами (yandex_vpc_network, yandex_vpc_subnet) через for_each из var.subnets; приватные подсети привязаны к route table (route_table_id).

NAT/RT: добавлены yandex_vpc_gateway и yandex_vpc_route_table (маршрут 0.0.0.0/0 через NAT).

Security Groups: без жёстких CIDR — используются атрибуты созданных подсетей; доступ на web — только от SG ALB.

Веб-ВМ: создаются в цикле for_each по var.web_nodes (масштабирование = добавление элемента).

ALB: Target Group — dynamic "target", Backend Group — target_group_ids.

Ansible: роли доведены до полной конфигурации сервисов (templates + handlers): nginx, zabbix_agent, elasticsearch, kibana, filebeat.

Proofs: добавлены логи (docs/terraform_plan.txt, docs/ansible_ping.txt, docs/ansible_apply.txt) и скриншоты (docs/screenshots/*).

Как проверить
Открыть внешний IP/имя ALB — должен отвечать статический сайт (Nginx) с inventory_hostname.

Zabbix UI доступен на публичном адресе; видны хосты и метрики (агенты подключены).

Kibana доступна на публичном адресе; в Discover появляются логи Nginx из web-серверов.

В Yandex Cloud видны: созданные сеть/подсети, NAT/RT, security groups, ВМ, ALB, snapshot-policy.
