variable "libvirt_uri" {
  description = "Libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

variable "docker_host" {
  description = "Docker daemon socket URI"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "vm_count" {
  description = "Number of Uncloud VM nodes to provision"
  type        = number
  default     = 2
  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 9
    error_message = "vm_count must be between 1 and 9."
  }
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs per Uncloud VM node"
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Memory (in MB) per Uncloud VM node"
  type        = number
  default     = 2048
}

variable "vm_autostart" {
  description = "Start Uncloud VMs automatically with libvirtd when the host boots"
  type        = bool
  default     = false
}

variable "vm_disk_gb" {
  description = "Root disk size (in GB) per Uncloud VM node"
  type        = number
  default     = 20
}

variable "ubuntu_release" {
  description = "Ubuntu Server cloud image release version"
  type        = string
  default     = "24.04"
}

variable "ubuntu_image_url" {
  description = "Optional override URL or local path for the Ubuntu cloud image"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for the Uncloud libvirt bridge network"
  type        = string
  default     = "10.240.0.0/24"
}

variable "bridge_name" {
  description = "Linux bridge interface name created by libvirt"
  type        = string
  default     = "br-uncloud"
}

variable "domain_suffix" {
  description = "Internal DNS zone suffix for the lab"
  type        = string
  default     = "internal"
}

variable "ssh_user" {
  description = "Default SSH user configured via cloud-init on each VM"
  type        = string
  default     = "playground"
}

variable "dns_image" {
  description = "Technitium DNS Server container image (pinned for reproducible applies)"
  type        = string
  default     = "technitium/dns-server:15.6.2"
}

variable "dns_admin_password" {
  description = "Admin password for the Technitium DNS Server web console and HTTP API"
  type        = string
  default     = "uncloud-lab-admin"
  sensitive   = true
}

variable "dns_web_port" {
  description = "Technitium DNS HTTP console/API port bound on the bridge gateway IP"
  type        = number
  default     = 5380
}

variable "dns_forwarders" {
  description = "Comma-separated upstream DNS resolvers for Technitium"
  type        = string
  default     = "1.1.1.1,8.8.8.8"
}

locals {
  lab_root      = abspath("${path.module}/..")
  cache_dir     = "${local.lab_root}/.cache"
  pool_dir      = "${local.cache_dir}/pool"
  uncloud_cfg   = "${local.cache_dir}/uncloud/config.yaml"
  root_ca_path  = "${local.cache_dir}/caddy-uncloud-root.crt"
  ssh_key_path  = "${local.cache_dir}/id_ed25519"
  subnet_prefix = tonumber(split("/", var.subnet_cidr)[1])
  gateway_ip    = cidrhost(var.subnet_cidr, 1)

  image_source = var.ubuntu_image_url != "" ? var.ubuntu_image_url : (
    "https://cloud-images.ubuntu.com/releases/${var.ubuntu_release}/release/ubuntu-${var.ubuntu_release}-server-cloudimg-amd64.img"
  )

  nodes = [
    for idx in range(var.vm_count) : {
      index    = idx
      num      = idx + 1
      name     = "uc-node-${idx + 1}"
      ip       = cidrhost(var.subnet_cidr, 11 + idx)
      mac      = format("52:54:00:fa:00:%02x", idx + 1)
      hostname = "uc-node-${idx + 1}"
      fqdn     = "uc-node-${idx + 1}.${var.domain_suffix}"
    }
  ]
}
