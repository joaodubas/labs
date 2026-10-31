terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    technitium = {
      source  = "kenske/technitium"
      version = "~> 0.2.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

provider "docker" {
  host = var.docker_host
}

provider "technitium" {
  host     = "http://${local.gateway_ip}:${var.dns_web_port}"
  username = "admin"
  password = var.dns_admin_password
}
