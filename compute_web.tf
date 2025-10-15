resource "yandex_compute_instance" "web" {
  for_each    = var.web_nodes
  name        = each.key
  zone        = each.value.zone
  platform_id = "standard-v3"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 10
      type     = "network-hdd"
    }
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnets[each.value.subnet].id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
    nat                = false
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_pub_key}"
  }
}
