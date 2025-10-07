\# Security



\- Секреты и var-файлы не коммитим (`\*.tfvars`, `serviceaccountkeyfile.json`, ansible-vault).

\- Доступ к приватным ВМ — только через Bastion (ProxyJump).

\- Security Groups открывают только нужные порты (ALB :80, Zabbix UI :80/443, Kibana :5601, Bastion :22).



