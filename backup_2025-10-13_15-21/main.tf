terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.146.0"
    }
  }
}

provider "yandex" {
  # Один из способов аутентификации (раскомментируй ОДИН):
  # token                    = var.yc_token
  service_account_key_file = var.sa_key_file

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone_a
}

# Общие локали, которые используют другие файлы (compute_*.tf и т.п.)
locals {
  platform_id = "standard-v3"
  ssh_key     = var.ssh_pub_key
}
