resource "yandex_vpc_gateway" "egress" {
  name = "egress-gw"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat" {
  name       = "rt-nat"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress.id
  }
}
