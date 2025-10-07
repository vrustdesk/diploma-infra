Diploma Infrastructure (Yandex Cloud)

Инфраструктура отказоустойчивого веб-сайта в Yandex Cloud на Terraform + Ansible.

Архитектура

2 веб-сервера Nginx в разных зонах (private)

Application Load Balancer (public, порт 80)

Bastion host (public SSH jump) для доступа во внутренний контур

Zabbix: сервер (public, UI) + агенты на всех ВМ

Elasticsearch (private) + Kibana (public)

Security Groups, NAT, приватные/публичные подсети

Ежедневные snapshot дисков всех ВМ

Структура репозитория
.
├── *.tf                        # Terraform-модули (VPC, SG, VM, ALB, NAT, snapshots)
├── README.md
├── Structure.txt              # Краткое дерево проекта
└── ansible/
    ├── hosts.ini
    ├── site.yml
    └── roles/
        ├── web/
        │   └── tasks/main.yml
        ├── zabbix/
        │   └── tasks/main.yml
        └── elastic/
            └── tasks/main.yml


Файлы terraform.tfstate* и .terraform/ не коммитятся (добавлены в .gitignore).

Предусловия

Аккаунт в Yandex Cloud + сервисный аккаунт/авторизация для Terraform

terraform >= 1.5

Рабочий SSH-ключ ~/.ssh/id_ed25519 (или другой путь, см. hosts.ini)

Управляющая машина с Ansible (можно запускать с bastion)

Развёртывание
1) Terraform
terraform init
terraform plan
terraform apply


После apply вы получите:

публичный IP bastion

публичный IP kibana

публичный IP zabbix

публичный IP (или FQDN) ALB для веб-сайта

Не выкладывайте токены/переменные окружения в git.

2) Ansible

Перейдите в каталог ansible/:

cd ansible
ansible-playbook -i hosts.ini site.yml


Пример hosts.ini:

[web]
web-a.ru-central1.internal
web-b.ru-central1.internal

[elk]
es-a.ru-central1.internal
kibana.ru-central1.internal

[zabbix]
zabbix.ru-central1.internal

[bastion]
bastion.ru-central1.internal

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
# Замените <BASTION_PUBLIC_IP> на фактический IP из Terraform outputs
ansible_ssh_common_args='-o ProxyJump=ubuntu@<BASTION_PUBLIC_IP>'


Минимальный site.yml:

---
- hosts: web
  become: true
  roles:
    - role: web        # nginx + простая страница
    - role: zabbix     # агент zabbix
    - role: elastic    # filebeat (лог-агент для nginx)

- hosts: zabbix
  become: true
  roles:
    - role: zabbix     # сервер или донастройка агента (по месту)

- hosts: elk
  become: true
  roles:
    - role: elastic    # elastic/kibana или клиенты (в этом проекте основной упор на filebeat на web)

Роли Ansible (сниппеты)
roles/web/tasks/main.yml — Nginx
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Enable & start nginx
  service:
    name: nginx
    state: started
    enabled: yes

- name: Create test index.html
  copy:
    dest: /var/www/html/index.html
    content: |
      <h1>OK - {{ inventory_hostname }}</h1>

roles/elastic/tasks/main.yml — Filebeat (отправка логов nginx в Elasticsearch)
---
- name: Install Filebeat
  apt:
    deb: https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.9.1-amd64.deb
  register: fb_installed
  changed_when: "'Setting up filebeat' in (fb_installed.stdout | default('')) or 'Setting up filebeat' in (fb_installed.stderr | default(''))"
  failed_when: false

- name: Deploy filebeat.yml
  copy:
    dest: /etc/filebeat/filebeat.yml
    mode: '0644'
    content: |
      filebeat.inputs:
        - type: log
          enabled: true
          paths:
            - /var/log/nginx/access.log*
            - /var/log/nginx/error.log*

      output.elasticsearch:
        hosts: ["http://es-a.ru-central1.internal:9200"]

      setup.kibana:
        host: "http://kibana.ru-central1.internal:5601"

      setup.template.enabled: true
      setup.ilm.enabled: auto
  notify: Restart filebeat

- name: Enable nginx module (idempotent)
  command: filebeat modules enable nginx
  args:
    creates: /etc/filebeat/modules.d/nginx.yml

- name: Enable & start Filebeat
  service:
    name: filebeat
    state: started
    enabled: yes

handlers:
  - name: Restart filebeat
    service:
      name: filebeat
      state: restarted

roles/zabbix/tasks/main.yml — агент Zabbix (и/или сервер)
---
- name: Install Zabbix repo
  apt:
    deb: https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-1+ubuntu22.04_all.deb

- name: Update apt
  apt:
    update_cache: yes

- name: Install zabbix-agent
  apt:
    name: zabbix-agent
    state: present

- name: Configure zabbix_agentd.conf
  copy:
    dest: /etc/zabbix/zabbix_agentd.conf
    mode: '0644'
    content: |
      Server=zabbix.ru-central1.internal
      ServerActive=zabbix.ru-central1.internal
      Hostname={{ inventory_hostname }}
      Include=/etc/zabbix/zabbix_agentd.d/*.conf
  notify: Restart zabbix-agent

- name: Enable & start zabbix-agent
  service:
    name: zabbix-agent
    state: started
    enabled: yes

handlers:
  - name: Restart zabbix-agent
    service:
      name: zabbix-agent
      state: restarted

Доступ к сервисам
Сервис	Адрес (пример)	Примечание
Веб-сайт	http://<ALB_PUBLIC_IP>	порт 80
Kibana	http://<KIBANA_PUBLIC_IP>:5601	лог-мониторинг
Zabbix	http://<ZABBIX_PUBLIC_IP>/zabbix	метрики, дашборды

Подставьте реальные IP из Terraform outputs.

Проверка

ALB: curl -v http://<ALB_PUBLIC_IP>/ — ответ с одного из web-серверов

Kibana: в Discover видны индексы filebeat-* и логи nginx

Zabbix: хосты web-a, web-b, kibana, es-a, bastion в статусе Up; метрики CPU/RAM/диск/сеть собираются

Snapshots: в разделе Compute → Снимки дисков появились ежедневные снапшоты

Замечания по безопасности

Никогда не коммитьте terraform.tfstate, ключи и секреты

ansible_ssh_common_args использует ProxyJump через bastion — прямого доступа к private-ВМ нет

Порты SG открываются только под конкретные сервисы (80/5601/22 и т.п.)

Лицензия

MIT / по договорённости.