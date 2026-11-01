resource "libvirt_network" "uncloud" {
  name      = "uncloud"
  mode      = "nat"
  bridge    = var.bridge_name
  domain    = var.domain_suffix
  addresses = [var.subnet_cidr]
  autostart = true

  # Keep libvirt's dnsmasq off 10.240.0.1:53 so the Technitium DNS container
  # can bind it directly (TCP/UDP). NOTE: `dns { enabled = false }` alone is
  # silently ignored by the dmacvicar/libvirt provider (d.GetOk treats false
  # as unset, so <dns enable='no'/> is never emitted and libvirt's default is
  # DNS *enabled*). dnsmasq's port=0 disables its DNS listener regardless of
  # provider/libvirt version; with DHCP also disabled, dnsmasq does nothing.
  dns {
    enabled = false
  }

  dhcp {
    enabled = false
  }

  dnsmasq_options {
    options {
      option_name  = "port"
      option_value = "0"
    }
  }
}
