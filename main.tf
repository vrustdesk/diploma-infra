terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.146.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1grjilo95o7gran384k"
  folder_id = "b1g7c88s4qad127pca97"
  zone      = "ru-central1-a"
  # путь к ключу сервисного аккаунта на твоей машине
  service_account_key_file = "C:/yandex cloud/yc/authorized_key.json"
}

# Общие переменные
locals {
  platform_id = "standard-v3"
  ssh_key     = chomp(file("C:/Users/A.K/.ssh/id_ed25519.pub"))
}

# Уже существующая в каталоге сеть и три дефолтные подсети
data "yandex_vpc_network" "net" { name = "default" }

data "yandex_vpc_subnet" "public_d" { name = "default-ru-central1-d" }
data "yandex_vpc_subnet" "private_a" { name = "default-ru-central1-a" }
data "yandex_vpc_subnet" "private_b" { name = "default-ru-central1-b" }
