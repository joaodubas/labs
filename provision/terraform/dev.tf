resource "digitalocean_tag" "dev_tag" {
  name = "dev"
}

resource "digitalocean_droplet" "dev_server" {
  name = "dev"
  region = "nyc3"
  image = "ubuntu-18-04-x64"
  size = "s-2vcpu-4gb"
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

resource "digitalocean_domain" "dev_default" {
  name = "dubas.dev"
  ip_address = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_coder" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "coder"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_sentry" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "sentry"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_pgadmin" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "pgadmin"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_voltdb" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "voltdb"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_sourcegraph" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "sourcegraph"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_admin_sourcegraph" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "admin.sourcegraph"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_elastic" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "elastic"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_elasticui" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "elasticui"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_grafana" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "grafana"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_emcasa_backend" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "api.emcasa"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_emcasa_octopus" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "octopus.emcasa"
  value = digitalocean_droplet.dev_server.ipv4_address
}

resource "digitalocean_record" "dev_emcasa_salesforce" {
  domain = digitalocean_domain.dev_default.name
  type = "A"
  name = "salesforce.emcasa"
  value = digitalocean_droplet.dev_server.ipv4_address
}
