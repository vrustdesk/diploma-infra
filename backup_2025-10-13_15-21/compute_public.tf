data "yandex_compute_image" "ubuntu" {
  family    = "ubuntu-2204-lts"
  folder_id = "standard-images"
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = local.platform_id
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = local.platform_id
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.elk_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = local.platform_id
  zone        = "ru-central1-d"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}
