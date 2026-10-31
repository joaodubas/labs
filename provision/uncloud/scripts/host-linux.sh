#!/usr/bin/env bash
# Host setup, Root CA trust, and cleanup helper for native Ubuntu Linux and WSL2.
#
# Usage:
#   scripts/host-linux.sh prereqs    # verify libvirtd, docker, uc CLI, and configure systemd-resolved
#   scripts/host-linux.sh trust-ca   # extract/install Caddy internal Root CA into system + NSS stores (+ Windows if WSL2)
#   scripts/host-linux.sh cleanup    # remove systemd-resolved drop-in, Root CA, and Windows rules (if WSL2)
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$LAB_DIR/.cache"
ROOT_CA_FILE="$CACHE_DIR/caddy-uncloud-root.crt"
SSH_KEY_FILE="$CACHE_DIR/id_ed25519"
SYSTEM_CA_DEST="/usr/local/share/ca-certificates/uncloud-internal-root.crt"
RESOLVED_DROPIN="/etc/systemd/resolved.conf.d/uncloud-internal.conf"
CERT_NICKNAME="Uncloud Internal Lab Root CA"
# Prefer Terraform outputs so custom variable values (subnet_cidr,
# domain_suffix, ...) stay in sync; fall back to the defaults when there is
# no state yet (e.g. 'prereqs' before the first apply) or terraform is
# not installed yet.
tf_output() {
  command -v terraform >/dev/null 2>&1 || return 0
  terraform -chdir="$LAB_DIR/terraform" output -raw "$1" 2>/dev/null || true
}

DNS_IP="${DNS_IP:-$(tf_output bridge_gateway_ip)}"
DNS_IP="${DNS_IP:-10.240.0.1}"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-$(tf_output domain_suffix)}"
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-internal}"
SEED_NODE_IP="${SEED_NODE_IP:-$(tf_output seed_node_ip)}"
SEED_NODE_IP="${SEED_NODE_IP:-10.240.0.11}"
SSH_USER="${SSH_USER:-playground}"

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

ensure_packages() {
  local missing=()
  command -v virsh >/dev/null 2>&1 || missing+=(libvirt-daemon-system libvirt-clients bridge-utils)
  command -v qemu-system-x86_64 >/dev/null 2>&1 || missing+=(qemu-system-x86 qemu-utils cloud-image-utils)
  command -v certutil >/dev/null 2>&1 || missing+=(libnss3-tools)

  if [ "${#missing[@]}" -gt 0 ]; then
    echo ">> installing missing host packages: ${missing[*]}"
    sudo apt-get update -y
    sudo apt-get install -y "${missing[@]}"
  fi
}

ensure_services() {
  echo ">> ensuring libvirtd and docker services are running"
  sudo systemctl enable --now libvirtd
  sudo systemctl enable --now docker

  # Allow libvirt qemu processes to read volumes inside $LAB_DIR/.cache/pool
  mkdir -p "$CACHE_DIR/pool" "$CACHE_DIR/uncloud"
  chmod 755 "$CACHE_DIR" "$CACHE_DIR/pool"

  # On Ubuntu with AppArmor, ensure qemu-system-x86_64 can access custom directory pools if security_driver isn't none
  if [ -f /etc/libvirt/qemu.conf ]; then
    if ! sudo grep -q '^security_driver = "none"' /etc/libvirt/qemu.conf; then
      echo ">> configuring libvirtd qemu.conf security_driver = \"none\" for local workspace storage pool compatibility"
      echo 'security_driver = "none"' | sudo tee -a /etc/libvirt/qemu.conf >/dev/null
      sudo systemctl restart libvirtd
    fi
  fi
}

ensure_uc_cli() {
  if command -v uc >/dev/null 2>&1; then
    echo ">> uncloud CLI (uc) already installed: $(command -v uc)"
    return 0
  fi
  echo ">> installing uncloud CLI (uc) via https://get.uncloud.run/install.sh"
  curl -fsS https://get.uncloud.run/install.sh | sh
}

configure_resolved() {
  echo ">> configuring systemd-resolved split-DNS (~${DOMAIN_SUFFIX} -> ${DNS_IP})"
  sudo mkdir -p "$(dirname "$RESOLVED_DROPIN")"
  sudo tee "$RESOLVED_DROPIN" >/dev/null <<EOF
[Resolve]
DNS=${DNS_IP}
Domains=~${DOMAIN_SUFFIX}
EOF
  sudo systemctl restart systemd-resolved || true
}

extract_root_ca_if_missing() {
  if [ -s "$ROOT_CA_FILE" ]; then
    return 0
  fi
  if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "warning: SSH key $SSH_KEY_FILE not found; cannot extract Root CA from $SEED_NODE_IP" >&2
    return 1
  fi

  echo ">> attempting to fetch Caddy internal Root CA from $SEED_NODE_IP ..."
  curl -ksS --resolve "init.${DOMAIN_SUFFIX}:443:${SEED_NODE_IP}" "https://init.${DOMAIN_SUFFIX}" >/dev/null 2>&1 || true

  local caddy_cid
  caddy_cid=$(ssh -i "$SSH_KEY_FILE" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    "${SSH_USER}@${SEED_NODE_IP}" \
    "sudo docker ps --filter 'name=caddy' --format '{{.ID}}' | head -n1" 2>/dev/null || true)

  if [ -n "$caddy_cid" ]; then
    ssh -i "$SSH_KEY_FILE" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      "${SSH_USER}@${SEED_NODE_IP}" \
      "sudo docker exec $caddy_cid cat /data/caddy/pki/authorities/local/root.crt" > "$ROOT_CA_FILE" 2>/dev/null || true
  fi

  [ -s "$ROOT_CA_FILE" ]
}

find_nss_dirs() {
  local dirs=()
  if [ -d "$HOME/.pki/nssdb" ]; then
    dirs+=("$HOME/.pki/nssdb")
  else
    mkdir -p "$HOME/.pki/nssdb"
    certutil -d "sql:$HOME/.pki/nssdb" -N --empty-password >/dev/null 2>&1 || true
    dirs+=("$HOME/.pki/nssdb")
  fi

  local search_roots=(
    "$HOME/.mozilla/firefox"
    "$HOME/snap/firefox/common/.mozilla/firefox"
    "$HOME/snap/chromium/current/.pki/nssdb"
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    "$HOME/.var/app/io.github.zen_browser.zen/.zen"
    "$HOME/.zen"
  )

  for root in "${search_roots[@]}"; do
    if [ -d "$root" ]; then
      while IFS= read -r -d '' db; do
        dirs+=("$(dirname "$db")")
      done < <(find "$root" -maxdepth 3 -name "cert9.db" -print0 2>/dev/null)
    fi
  done

  printf '%s\n' "${dirs[@]}" | sort -u
}

sync_windows_host() {
  local action="$1"
  if ! is_wsl; then
    return 0
  fi
  if ! command -v powershell.exe >/dev/null 2>&1 || ! command -v wslpath >/dev/null 2>&1; then
    return 0
  fi

  local ps_script_win
  ps_script_win="$(wslpath -w "$LAB_DIR/scripts/host-access.ps1")"
  local wsl_ip
  wsl_ip="$(hostname -I | awk '{print $1}')"

  echo ">> WSL2 detected — configuring Windows host access ($action)"
  echo "   (Note: NRPT and route changes on Windows require an Administrator PowerShell prompt)"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps_script_win" \
    -Action "$action" \
    -WslIp "$wsl_ip" \
    -DnsIp "$DNS_IP" || {
      echo ">> To complete Windows host setup with Administrator privileges, run in an elevated PowerShell on Windows:"
      echo "   pwsh -ExecutionPolicy Bypass -File \"$ps_script_win\" -Action $action -WslIp $wsl_ip"
    }
}

cmd_prereqs() {
  ensure_packages
  ensure_services
  ensure_uc_cli
  configure_resolved
  echo ">> Linux/WSL2 prerequisites ready"
}

cmd_trust_ca() {
  if ! extract_root_ca_if_missing; then
    echo "warning: Root CA file ($ROOT_CA_FILE) not available yet." >&2
    return 0
  fi

  echo ">> installing Caddy Root CA into system trust store ($SYSTEM_CA_DEST)"
  sudo cp "$ROOT_CA_FILE" "$SYSTEM_CA_DEST"
  sudo chmod 0644 "$SYSTEM_CA_DEST"
  sudo update-ca-certificates

  if command -v certutil >/dev/null 2>&1; then
    while IFS= read -r nss_dir; do
      [ -n "$nss_dir" ] || continue
      echo ">> importing Root CA into NSS DB: $nss_dir"
      certutil -d "sql:$nss_dir" -D -n "$CERT_NICKNAME" >/dev/null 2>&1 || true
      certutil -d "sql:$nss_dir" -A -t "C,," -n "$CERT_NICKNAME" -i "$ROOT_CA_FILE" || true
    done < <(find_nss_dirs)
  fi

  sync_windows_host "Up"
}

cmd_cleanup() {
  echo ">> cleaning up host DNS and Root CA configuration"
  if [ -f "$RESOLVED_DROPIN" ]; then
    sudo rm -f "$RESOLVED_DROPIN"
    sudo systemctl restart systemd-resolved || true
  fi

  if [ -f "$SYSTEM_CA_DEST" ]; then
    sudo rm -f "$SYSTEM_CA_DEST"
    sudo update-ca-certificates --fresh >/dev/null 2>&1 || sudo update-ca-certificates
  fi

  if command -v certutil >/dev/null 2>&1; then
    while IFS= read -r nss_dir; do
      [ -n "$nss_dir" ] || continue
      certutil -d "sql:$nss_dir" -D -n "$CERT_NICKNAME" >/dev/null 2>&1 || true
    done < <(find_nss_dirs)
  fi

  sync_windows_host "Down"
  echo ">> host cleanup finished"
}

case "${1:-}" in
  prereqs) cmd_prereqs ;;
  trust-ca) cmd_trust_ca ;;
  cleanup) cmd_cleanup ;;
  *)
    sed -n '2,7p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
