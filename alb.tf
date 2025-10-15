resource "yandex_alb_target_group" "web_tg" {
  name = "tg-web"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id  = target.value.network_interface[0].subnet_id
      ip_address = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web_bg" {
  name = "bg-web"

  http_backend {
    name = "web-http"
    port = 80

    target_group_ids = [yandex_alb_target_group.web_tg.id]

    healthcheck {
      http_healthcheck {
        path = "/"
      }
      interval            = "5s"
      timeout             = "3s"
      unhealthy_threshold = 2
      healthy_threshold   = 2
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name = "router-web"
}

resource "yandex_alb_virtual_host" "web_vh" {
  name           = "vh-web"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "root"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_alb" {
  name       = "alb-web"
  network_id = yandex_vpc_network.main.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnets["public_d"].id
    }
  }

  listener {
    name = "http"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  security_group_ids = [yandex_vpc_security_group.alb_sg.id]
}
