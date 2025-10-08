# Diploma Infrastructure (Yandex Cloud)

Отказоустойчивая инфраструктура сайта: **Terraform + Ansible**, мониторинг (Zabbix), логи (Filebeat → Elasticsearch + Kibana), бэкапы (snapshots).  
Все токены/ключи вне git. Для проверки достаточно кода и скриншотов.

## Архитектура

- 2× Nginx web (private, разные зоны)
- Application Load Balancer (public :80, health-check `/`)
- Bastion host (public SSH jump)
- Elasticsearch (private) + Kibana (public)
- Zabbix server (public UI) + агенты на всех ВМ
- 1× VPC: private/public subnets, NAT gateway, Security Groups
- Daily snapshots, retention 7 дней

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



Как развернуть

Terraform

terraform init
terraform plan -var-file=./examples/terraform.tfvars.example
terraform apply -var-file=./examples/terraform.tfvars.example



Ansible

Инвентори использует FQDN .ru-central1.internal + ProxyJump через bastion.

cd ansible
ansible all -m ping
ansible-playbook -i hosts.ini site.yml


Скриншоты (proof)

См. docs/screenshots/:

VPC/Subnets/SG/NAT/VMs/ALB — yc-*.png

ALB health-check — alb-healthchecks.png

curl -v к сайту через ALB — curl-80.png

Zabbix dashboards/hosts — zabbix-*.png

Kibana discover/index pattern — kibana-*.png

Elasticsearch cluster health — elastic-cluster-health.png

Snapshot policy — snapshots-policy.png

terraform apply, ansible ping — terraform-apply.png, ansible-ping.png

Решения и компромиссы

Минимальные ВМ: 2 vCPU (20% Ice Lake), 2–4 GB RAM, 10 GB HDD, прерываемые (перед сдачей переведены в постоянные).

Веб-ВМ без внешних IP (только приватная сеть), доступ — через Bastion.

Исходящий интернет для приватных ВМ — через NAT.

Логи: Filebeat (web) → Elasticsearch; UI в Kibana.

Мониторинг: Zabbix USE (CPU/RAM/Disk/Net) + Web scenario /.

Бэкапы: snapshot schedule ежедневно, retention 7 дней.

Безопасность: секьюрные SG, секреты вне репозитория.
