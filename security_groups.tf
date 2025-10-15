# Bastion
resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "sg-bastion"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "yandex_vpc_security_group" "alb_sg" {
  name       = "sg-alb"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "HTTP from Internet"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# WEB (HTTP только от ALB, zabbix-agent от Zabbix)
resource "yandex_vpc_security_group" "web_sg" {
  name       = "sg-web"
  network_id = yandex_vpc_network.main.id

  ingress {
    description       = "HTTP from ALB"
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb_sg.id
  }

  ingress {
    description       = "Zabbix agent"
    protocol          = "TCP"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_sg.id
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "sg-zabbix"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "Zabbix UI"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Zabbix server port"
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = flatten([for s in yandex_vpc_subnet.subnets : s.v4_cidr_blocks])
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ELK
resource "yandex_vpc_security_group" "elk_sg" {
  name       = "sg-elk"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "Kibana"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Elasticsearch from private subnets"
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = flatten([for s in yandex_vpc_subnet.subnets : s.v4_cidr_blocks])
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
