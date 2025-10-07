resource "yandex_alb_target_group" "web_tg" {
  name = "web-tg"

  target {
    subnet_id  = data.yandex_vpc_subnet.private_a.id
    ip_address = yandex_compute_instance.web_a.network_interface[0].ip_address
  }

  target {
    subnet_id  = data.yandex_vpc_subnet.private_b.id
    ip_address = yandex_compute_instance.web_b.network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "web_bg" {
  name = "web-bg"

  http_backend {
    name             = "http-80"
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      interval         = "2s"
      timeout          = "1s"
      healthcheck_port = 80
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-vhost"
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
  name       = "web-alb"
  network_id = data.yandex_vpc_network.net.id

  # SG для ALB (должен существовать)
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-d"
      subnet_id = data.yandex_vpc_subnet.public_d.id
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
}
