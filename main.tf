terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "yandex_cloud_token" {
  type = string
  description = "y0_AgAAAAAGdhqDAATu.......yvd9So"
}

provider "yandex" {
  token     = var.yandex_cloud_token  #секретные данные должны быть в сохранности!! Никогда не выкладывайте токен в публичный доступ.
  cloud_id  = "b1ghmbbcc16prrludk63"  #_https://console.cloud.yandex.ru/cloud/b1ghmbbcc16prrludk63
  folder_id = "b1gltt4aeqoofm7e2pnj"  #_https://console.cloud.yandex.ru/folders/b1gltt4aeqoofm7e2pnj
  zone      = "ru-central1-b"         #_https://cloud.yandex.ru/docs/overview/concepts/geo-scope
}

resource "yandex_compute_instance" "server" {
  count = 2
  name = "server${count.index}"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8li2lvvfc6bdj4c787"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_lb_target_group" "group-1" {
  name      = "group-1"
  
  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.server[0].network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.server[1].network_interface.0.ip_address
  }
}

resource "yandex_lb_network_load_balancer" "load-balancer-1" {
  name = "load-balancer-1"
  deletion_protection = "false"
  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.group-1.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "internal_ip_address_server_0" {
  value = yandex_compute_instance.server[0].network_interface.0.ip_address
}

output "external_ip_address_server_0" {
  value = yandex_compute_instance.server[0].network_interface.0.nat_ip_address
}

output "internal_ip_address_server_1" {
  value = yandex_compute_instance.server[1].network_interface.0.ip_address
}

output "external_ip_address_server_1" {
  value = yandex_compute_instance.server[1].network_interface.0.nat_ip_address
}
