resource "digitalocean_tag" "dev_tag" {
  name = "dev"
}

resource "digitalocean_droplet" "dev_server" {
  name = "dev"
  region = "nyc3"
  # image = "ubuntu-18-04-x64"
  image = "42892184"
  size = "s-4vcpu-8gb"
  # size = "s-2vcpu-4gb"
  private_networking = true
  tags = [
    digitalocean_tag.dev_tag.name
  ]
  ssh_keys = [
    var.ssh_fingerprint
  ]
  connection {
    user = "root"
    type = "ssh"
    host = digitalocean_droplet.dev_server.ipv4_address
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "EXPORT PATH=$PATH:/usr/bin",
      # install python
      "apt-get -y update",
      "apt-get -y install python python3 python-pip python3-pip"
    ]
  }

  provisioner "local-exec" {
    # NOTE (jpd): since docker-machine doesn't allow ad-hoc provisioning, we use generic driver to provision our droplet
    # see: https://www.digitalocean.com/community/questions/how-can-i-attach-docker-machine-to-an-existing-droplet-created-with-another-docker-machine#answer_25975
    command = "docker-machine create --driver generic --generic-ip-address ${digitalocean_droplet.dev_server.ipv4_address} --generic-ssh-key ${var.pvt_key} dev"
  }
}

resource "digitalocean_firewall" "dev_firewall" {
  name = "dev-ssh-http-https"
  droplet_ids = [
    digitalocean_droplet.dev_server.id
  ]
  tags = [
    digitalocean_tag.dev_tag.name
  ]
  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "222"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol = "udp"
    port_range = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol = "tcp"
    port_range = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_domain" "dev_default" {
  name = "dubas.dev"
  ip_address = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_auth" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "auth"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_affine" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "affine"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_bitwarden" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "bitwarden"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_coder" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "coder"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_ec_api" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "api.ec"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_ec_bot" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "bot"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_gitea" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "gitea"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_drone" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "drone"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_nlw_wabanex" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "wabanex"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_minio" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "minio"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_minio_console" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "console.minio"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_grafana" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "grafana"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_uptime" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "uptime"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "simplelogin_mx_1" {
  domain = digitalocean_domain.dev_default.name
  type = "MX"
  name = "@"
  priority = 10
  value = "mx1.simplelogin.co."
}

resource "digitalocean_record" "simplelogin_mx_2" {
  domain = digitalocean_domain.dev_default.name
  type = "MX"
  name = "@"
  priority = 20
  value = "mx2.simplelogin.co."
}

resource "digitalocean_record" "simplelogin_spf" {
  domain = digitalocean_domain.dev_default.name
  type = "TXT"
  name = "@"
  value = "v=spf1 include:simplelogin.co -all"
}

resource "digitalocean_record" "simplelogin_dkim" {
  domain = digitalocean_domain.dev_default.name
  type = "CNAME"
  name = "dkim._domainkey"
  value = "dkim._domainkey.simplelogin.co."
}

resource "digitalocean_record" "simplelogin_dmarc" {
  domain = digitalocean_domain.dev_default.name
  type = "TXT"
  name = "_dmarc"
  value = "v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s"
}
