resource "yandex_vpc_network" "main" {
  name = "main-net"
}

# Подсети создаём в цикле по var.subnets
resource "yandex_vpc_subnet" "subnets" {
  for_each       = var.subnets
  name           = "subnet-${each.key}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = each.value.cidr

  # Привязка Route Table только к приватным
  route_table_id = contains(["private_a", "private_b"], each.key) ? yandex_vpc_route_table.nat.id : null
}
