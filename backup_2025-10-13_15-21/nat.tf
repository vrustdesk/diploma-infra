resource "yandex_vpc_gateway" "nat" {
  name = "nat-gw"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt_nat" {
  name       = "rt-nat"
  network_id = data.yandex_vpc_network.net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

output "rt_nat_id" { value = yandex_vpc_route_table.rt_nat.id }
