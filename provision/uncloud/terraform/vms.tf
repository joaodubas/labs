resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = local.ssh_key_path
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${local.ssh_key_path}.pub"
  file_permission = "0644"
}

resource "libvirt_pool" "uncloud" {
  name = "uncloud-pool"
  type = "dir"
  target {
    path = local.pool_dir
  }
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-${var.ubuntu_release}-base.qcow2"
  pool   = libvirt_pool.uncloud.name
  source = local.image_source
  format = "qcow2"
}

resource "libvirt_volume" "node_disk" {
  count          = var.vm_count
  name           = "${local.nodes[count.index].name}-root.qcow2"
  pool           = libvirt_pool.uncloud.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = var.vm_disk_gb * 1024 * 1024 * 1024
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "node_seed" {
  count = var.vm_count
  name  = "${local.nodes[count.index].name}-seed.iso"
  pool  = libvirt_pool.uncloud.name

  user_data = templatefile("${local.lab_root}/config/cloud-init/user-data.tftpl", {
    hostname       = local.nodes[count.index].hostname
    domain_suffix  = var.domain_suffix
    ssh_user       = var.ssh_user
    ssh_public_key = trimspace(tls_private_key.ssh.public_key_openssh)
  })

  network_config = templatefile("${local.lab_root}/config/cloud-init/network.tftpl", {
    mac_address   = local.nodes[count.index].mac
    ip_address    = local.nodes[count.index].ip
    subnet_prefix = local.subnet_prefix
    gateway_ip    = local.gateway_ip
    dns_ip        = local.gateway_ip
    domain_suffix = var.domain_suffix
  })
}

resource "libvirt_domain" "node" {
  count     = var.vm_count
  name      = local.nodes[count.index].name
  memory    = var.vm_memory_mb
  vcpu      = var.vm_vcpu
  autostart = false

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = libvirt_cloudinit_disk.node_seed[count.index].id

  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }

  network_interface {
    network_id     = libvirt_network.uncloud.id
    mac            = local.nodes[count.index].mac
    addresses      = [local.nodes[count.index].ip]
    wait_for_lease = false
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  depends_on = [
    libvirt_network.uncloud,
    local_sensitive_file.ssh_private_key,
  ]
}
