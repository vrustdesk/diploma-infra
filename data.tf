# Используем уже существующую "default" сеть и дефолтные подсети в ru-central1
data "yandex_vpc_network" "net" {
  name = "default"
}

# Публичная подсеть в зоне D (у Yandex Cloud именно так называются дефолтные)
data "yandex_vpc_subnet" "public_d" {
  name = "default-ru-central1-d"
}

# Приватные подсети в A и B
data "yandex_vpc_subnet" "private_a" {
  name = "default-ru-central1-a"
}

data "yandex_vpc_subnet" "private_b" {
  name = "default-ru-central1-b"
}
