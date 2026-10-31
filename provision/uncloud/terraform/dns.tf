resource "docker_image" "technitium" {
  name         = "technitium/dns-server:latest"
  keep_locally = true
}

resource "docker_volume" "technitium_config" {
  name = "uncloud-technitium-config"
}

resource "docker_container" "technitium" {
  name    = "uncloud-technitium-dns"
  image   = docker_image.technitium.image_id
  restart = "unless-stopped"

  env = [
    "DNS_SERVER_DOMAIN=dns.${var.domain_suffix}",
    "DNS_SERVER_ADMIN_PASSWORD=${var.dns_admin_password}",
    "DNS_SERVER_FORWARDERS=${var.dns_forwarders}",
    "DNS_SERVER_PREFER_IPV6=false",
  ]

  ports {
    ip       = local.gateway_ip
    internal = 53
    external = 53
    protocol = "udp"
  }

  ports {
    ip       = local.gateway_ip
    internal = 53
    external = 53
    protocol = "tcp"
  }

  ports {
    ip       = local.gateway_ip
    internal = 5380
    external = var.dns_web_port
    protocol = "tcp"
  }

  volumes {
    volume_name    = docker_volume.technitium_config.name
    container_path = "/etc/dns"
  }

  depends_on = [
    libvirt_network.uncloud,
  ]
}

resource "terraform_data" "wait_for_technitium" {
  triggers_replace = [
    docker_container.technitium.id,
  ]

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      echo ">> waiting for Technitium HTTP API on http://${local.gateway_ip}:${var.dns_web_port} ..."
      for _ in $(seq 1 60); do
        if curl -fsS "http://${local.gateway_ip}:${var.dns_web_port}/api/user/login?user=admin&pass=${urlencode(var.dns_admin_password)}" | grep -q '"status":"ok"'; then
          echo ">> Technitium HTTP API is ready"
          exit 0
        fi
        sleep 1
      done
      echo "error: Technitium HTTP API did not become ready in time" >&2
      exit 1
    EOT
  }

  depends_on = [
    docker_container.technitium,
  ]
}

resource "technitium_dns_zone" "internal" {
  name                       = var.domain_suffix
  type                       = "Primary"
  use_soa_serial_date_scheme = true

  depends_on = [
    terraform_data.wait_for_technitium,
  ]
}

resource "technitium_dns_zone_record" "dns_host" {
  zone       = technitium_dns_zone.internal.name
  domain     = "dns.${var.domain_suffix}"
  type       = "A"
  ip_address = local.gateway_ip
  ttl        = 60
  comments   = "Technitium DNS Server & br-uncloud gateway"

  depends_on = [
    technitium_dns_zone.internal,
  ]
}

resource "technitium_dns_zone_record" "node" {
  count      = var.vm_count
  zone       = technitium_dns_zone.internal.name
  domain     = local.nodes[count.index].fqdn
  type       = "A"
  ip_address = local.nodes[count.index].ip
  ttl        = 60
  comments   = "Uncloud VM node ${local.nodes[count.index].name}"

  depends_on = [
    technitium_dns_zone.internal,
  ]
}

resource "technitium_dns_zone_record" "wildcard" {
  count      = var.vm_count
  zone       = technitium_dns_zone.internal.name
  domain     = "*.${var.domain_suffix}"
  type       = "A"
  ip_address = local.nodes[count.index].ip
  ttl        = 60
  comments   = "Uncloud Caddy ingress round-robin (${local.nodes[count.index].name})"

  depends_on = [
    technitium_dns_zone.internal,
  ]
}
