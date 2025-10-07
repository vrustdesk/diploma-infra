\# Архитектура



\- 2× web (nginx) в приватных подсетях разных зон

\- ALB (public :80) с health-check `/`

\- Bastion (public SSH)

\- Elasticsearch (private) + Kibana (public)

\- Zabbix server (public UI) + агенты

\- NAT egress для исходящего трафика приватных ВМ

\- Daily snapshots (7 дней)



```mermaid

flowchart LR

&nbsp; internet((Internet)) --> ALB\[YC ALB :80]

&nbsp; subgraph Public

&nbsp;   Bastion\[(Bastion SSH)]

&nbsp;   Kibana\[(Kibana UI)]

&nbsp;   Zabbix\[(Zabbix UI)]

&nbsp; end

&nbsp; subgraph Private

&nbsp;   webA(Web A - nginx)

&nbsp;   webB(Web B - nginx)

&nbsp;   ES\[(Elasticsearch)]

&nbsp; end

&nbsp; ALB -->|HTTP| webA

&nbsp; ALB -->|HTTP| webB

&nbsp; webA <-- Filebeat --> ES

&nbsp; webB <-- Filebeat --> ES



