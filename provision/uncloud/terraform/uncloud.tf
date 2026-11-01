resource "terraform_data" "wait_for_vms_ssh" {
  count = var.vm_count

  triggers_replace = [
    libvirt_domain.node[count.index].id,
  ]

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      node_name="${local.nodes[count.index].name}"
      node_ip="${local.nodes[count.index].ip}"
      echo ">> waiting for SSH and cloud-init on $${node_name} ($${node_ip}) ..."
      for _ in $(seq 1 120); do
        if ssh -F "${local_file.ssh_config.filename}" \
             -o ConnectTimeout=5 \
             "$${node_ip}" "cloud-init status --wait >/dev/null 2>&1 || true; true" 2>/dev/null; then
          echo ">> $${node_name} ($${node_ip}) SSH is up"
          exit 0
        fi
        sleep 3
      done
      echo "error: SSH did not come up on $${node_name} ($${node_ip})" >&2
      exit 1
    EOT
  }

  depends_on = [
    libvirt_domain.node,
    local_sensitive_file.ssh_private_key,
    technitium_dns_zone_record.node,
  ]
}

resource "terraform_data" "uncloud_init" {
  triggers_replace = [
    libvirt_domain.node[0].id,
  ]

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export UNCLOUD_CONFIG="${local.uncloud_cfg}"
      mkdir -p "$(dirname "$UNCLOUD_CONFIG")"
      rm -f "$UNCLOUD_CONFIG"

      echo ">> initializing Uncloud seed node ${local.nodes[0].name} (${local.nodes[0].ip}) ..."
      uc machine init \
        --name "${local.nodes[0].name}" \
        --no-dns \
        -i "${local.ssh_key_path}" \
        "${var.ssh_user}@${local.nodes[0].ip}"
    EOT
  }

  depends_on = [
    terraform_data.wait_for_vms_ssh,
  ]
}

resource "terraform_data" "uncloud_add_node" {
  count = var.vm_count > 1 ? var.vm_count - 1 : 0

  # Destroy-time provisioners may only reference `self`, so the values the
  # destroy provisioner needs must be stored in `input`.
  input = {
    node_name   = local.nodes[count.index + 1].name
    uncloud_cfg = local.uncloud_cfg
  }

  triggers_replace = [
    terraform_data.uncloud_init.id,
    libvirt_domain.node[count.index + 1].id,
  ]

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export UNCLOUD_CONFIG="${self.input.uncloud_cfg}"
      node_name="${self.input.node_name}"

      # --no-reset: the VM itself is destroyed right after, so wiping its
      # containers/data first would be wasted work (and fails if unreachable).
      if [ -f "$UNCLOUD_CONFIG" ] && uc machine ls 2>/dev/null | grep -qw "$${node_name}"; then
        echo ">> deregistering $${node_name} from Uncloud cluster ..."
        uc machine rm -y --no-reset "$${node_name}" || true
      fi
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export UNCLOUD_CONFIG="${local.uncloud_cfg}"
      node_name="${local.nodes[count.index + 1].name}"
      node_ip="${local.nodes[count.index + 1].ip}"

      if uc machine ls 2>/dev/null | grep -qw "$${node_name}"; then
        echo ">> $${node_name} already registered in Uncloud cluster"
        exit 0
      fi

      echo ">> joining $${node_name} ($${node_ip}) to Uncloud cluster ..."
      uc machine add \
        --name "$${node_name}" \
        -i "${local.ssh_key_path}" \
        "${var.ssh_user}@$${node_ip}"
    EOT
  }

  depends_on = [
    terraform_data.uncloud_init,
  ]
}

resource "terraform_data" "uncloud_caddy" {
  triggers_replace = [
    terraform_data.uncloud_init.id,
    filesha256("${local.lab_root}/config/Caddyfile.global"),
  ]

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      export UNCLOUD_CONFIG="${local.uncloud_cfg}"
      echo ">> deploying global Caddy configuration (local_certs) across cluster ..."
      # uc caddy deploy has no -y flag (unlike uc deploy); its TUI runs in huh's
      # accessible mode when stdin is not a TTY, so piping 'y' is the supported
      # non-interactive path (EOF would cancel the deploy).
      echo y | uc caddy deploy --caddyfile "${local.lab_root}/config/Caddyfile.global"

      echo ">> waiting for Caddy internal PKI root certificate to be generated ..."
      seed_ip="${local.nodes[0].ip}"
      mkdir -p "$(dirname "${local.root_ca_path}")"

      # Trigger a TLS handshake against the seed node so Caddy initializes its local PKI authority if not yet created
      curl -ksS --resolve "init.${var.domain_suffix}:443:$${seed_ip}" "https://init.${var.domain_suffix}" >/dev/null 2>&1 || true

      for _ in $(seq 1 30); do
        caddy_cid=$(ssh -F "${local_file.ssh_config.filename}" \
          "$${seed_ip}" \
          "sudo docker ps --filter 'name=caddy' --format '{{.ID}}' | head -n1" 2>/dev/null || true)

        if [ -n "$${caddy_cid}" ]; then
          if ssh -F "${local_file.ssh_config.filename}" \
            "$${seed_ip}" \
            "sudo docker exec $${caddy_cid} test -f /data/caddy/pki/authorities/local/root.crt" 2>/dev/null; then
            ssh -F "${local_file.ssh_config.filename}" \
              "$${seed_ip}" \
              "sudo docker exec $${caddy_cid} cat /data/caddy/pki/authorities/local/root.crt" > "${local.root_ca_path}"
            echo ">> extracted Caddy Root CA to ${local.root_ca_path}"
            exit 0
          fi
        fi
        sleep 2
      done
      echo "warning: could not extract root.crt yet; deploy an HTTPS service and run 'mise run trust-ca'" >&2
    EOT
  }

  depends_on = [
    terraform_data.uncloud_init,
    terraform_data.uncloud_add_node,
  ]
}
