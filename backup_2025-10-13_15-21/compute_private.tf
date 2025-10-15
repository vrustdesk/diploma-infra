resource "yandex_compute_instance" "web_a" {
  name        = "web-a"
  hostname    = "web-a"
  platform_id = local.platform_id
  zone        = "ru-central1-a"

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
    subnet_id          = data.yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "web_b" {
  name        = "web-b"
  hostname    = "web-b"
  platform_id = local.platform_id
  zone        = "ru-central1-b"

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
    subnet_id          = data.yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "es_a" {
  name        = "es-a"
  hostname    = "es-a"
  platform_id = local.platform_id
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = 12
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elk_sg.id]
  }

  metadata = {
    "ssh-keys" = "yc-user:${local.ssh_key}"
  }

  scheduling_policy {
    preemptible = true
  }
}
