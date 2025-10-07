resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "bastion-sg"
  network_id = data.yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = data.yandex_vpc_network.net.id

  # SSH только из подсети бастиона (10.130.0.0/24)
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.130.0.0/24"]
  }

  # HTTP от ALB и внутренних хостов
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix-sg"
  network_id = data.yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # агенты с приватных подсетей
  ingress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elk_sg" {
  name       = "elk-sg"
  network_id = data.yandex_vpc_network.net.id

  # SSH с бастиона
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.130.0.0/24"]
  }

  # Kibana из интернета
  ingress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Elasticsearch только из приватных сетей
  ingress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для ALB (http + healthchecks)
resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-sg"
  network_id = data.yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    from_port         = 0
    to_port           = 65535
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
