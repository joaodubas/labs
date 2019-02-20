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
    "${digitalocean_tag.dev_tag.name}"
  ]
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  connection = {
    user = "root"
    type = "ssh"
    private_key = "${file(var.pvt_key)}"
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
