resource "libvirt_network" "uncloud" {
  name      = "uncloud"
  mode      = "nat"
  bridge    = var.bridge_name
  domain    = var.domain_suffix
  addresses = [var.subnet_cidr]
  autostart = true

  # Disable libvirt's built-in dnsmasq DNS listener on the bridge IP (10.240.0.1:53)
  # so the Technitium DNS container can bind directly to 10.240.0.1:53 (TCP/UDP).
  dns {
    enabled = false
  }

  dhcp {
    enabled = false
  }
}
