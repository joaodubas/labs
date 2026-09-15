#!/usr/bin/env bash
# QEMU/KVM playground VM — the real-system counterpart to the docker
# playground (provision/docker-compose.yml). The container has no systemd,
# so snap/flatpak/docker-daemon tasks can only be smoke-tested there; this
# VM boots a full Ubuntu cloud image with systemd, making the whole
# bootstrap DAG genuinely verifiable on a throwaway machine.
#
# Usage:
#   provision/vm/vm.sh up          # download image, create disk, boot, wait for ssh
#   provision/vm/vm.sh ssh         # shell into the VM
#   provision/vm/vm.sh provision   # copy provision/mise into the VM and run bootstrap.sh
#   provision/vm/vm.sh console     # tail the serial console (boot logs)
#   provision/vm/vm.sh down        # power off
#   provision/vm/vm.sh clean       # down + delete disk/image/keys (full reset)
#
# Tunables (env): UBUNTU_RELEASE (default 26.04), VM_CPUS (4), VM_MEM_MB (4096),
# VM_DISK_GB (30), VM_SSH_PORT (2222).
#
# All state lives in provision/vm/.cache/ (gitignored): base image, disk
# overlay, cloud-init seed, a dedicated ed25519 keypair, console log, pid.
#
# Prerequisites: qemu-system-x86, qemu-utils, cloud-image-utils (cloud-localds)
# and read access to /dev/kvm. On Linux these are installed by the bootstrap
# itself (the `linux:qemu` task); the script uses `sg kvm` when the current
# session predates the kvm group change.
set -euo pipefail

CACHE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.cache"
UBUNTU_RELEASE="${UBUNTU_RELEASE:-26.04}"
VM_CPUS="${VM_CPUS:-4}"
VM_MEM_MB="${VM_MEM_MB:-4096}"
VM_DISK_GB="${VM_DISK_GB:-30}"
VM_SSH_PORT="${VM_SSH_PORT:-2222}"
SSH_USER="playground"

BASE_IMG="$CACHE_DIR/ubuntu-${UBUNTU_RELEASE}-server-cloudimg-amd64.img"
DISK="$CACHE_DIR/disk.qcow2"
SEED="$CACHE_DIR/seed.iso"
KEY="$CACHE_DIR/id_ed25519"
CONSOLE_LOG="$CACHE_DIR/console.log"
PIDFILE="$CACHE_DIR/qemu.pid"

SSH_OPTS=(-i "$KEY" -p "$VM_SSH_PORT"
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR -o ConnectTimeout=5)
SSH_TARGET="${SSH_USER}@127.0.0.1"

mkdir -p "$CACHE_DIR"

vm_ssh() { ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "$@"; }

# /dev/kvm may be root:kvm while this session predates `usermod -aG kvm`;
# `sg kvm` re-evaluates group membership without a re-login (no password:
# membership already exists in /etc/group).
run_qemu() {
  if [ -w /dev/kvm ]; then
    "$@"
  else
    sg kvm -c "$*"
  fi
}

fetch_base_image() {
  [ -f "$BASE_IMG" ] && return 0
  local base_url="https://cloud-images.ubuntu.com/releases/${UBUNTU_RELEASE}/release"
  echo ">> downloading Ubuntu ${UBUNTU_RELEASE} server cloud image"
  curl -fL --retry 3 -o "$BASE_IMG" \
    "${base_url}/ubuntu-${UBUNTU_RELEASE}-server-cloudimg-amd64.img"
  echo ">> verifying checksum"
  curl -fsL --retry 3 -o "$CACHE_DIR/SHA256SUMS" "${base_url}/SHA256SUMS"
  (cd "$CACHE_DIR" && grep "ubuntu-${UBUNTU_RELEASE}-server-cloudimg-amd64.img" \
    SHA256SUMS | sha256sum -c -)
}

write_cloud_init() {
  [ -f "$SEED" ] && return 0
  cat > "$CACHE_DIR/user-data" <<EOF
#cloud-config
hostname: provision-playground
users:
  - name: ${SSH_USER}
    groups: [adm, sudo]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "${KEY}.pub")
ssh_pwauth: false
package_update: true
packages: [git, curl, gnupg]
EOF
  echo "instance-id: provision-playground-$(date +%s)" > "$CACHE_DIR/meta-data"
  cloud-localds "$SEED" "$CACHE_DIR/user-data" "$CACHE_DIR/meta-data"
}

is_running() {
  [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

wait_for_ssh() {
  echo ">> waiting for ssh (first boot runs cloud-init; can take a few minutes)"
  for _ in $(seq 1 120); do
    if vm_ssh true 2>/dev/null; then
      echo ">> ssh is up"
      return 0
    fi
    sleep 5
  done
  echo "error: ssh did not come up; check '$0 console'" >&2
  exit 1
}

cmd_up() {
  if is_running; then
    echo ">> VM already running (pid $(cat "$PIDFILE"))"
    return 0
  fi
  fetch_base_image
  [ -f "$KEY" ] || ssh-keygen -t ed25519 -N "" -f "$KEY" -C "provision-vm" -q
  [ -f "$DISK" ] || qemu-img create -f qcow2 -F qcow2 \
    -b "$BASE_IMG" "$DISK" "${VM_DISK_GB}G"
  write_cloud_init
  echo ">> booting VM (cpus=$VM_CPUS mem=${VM_MEM_MB}M disk=${VM_DISK_GB}G port=$VM_SSH_PORT)"
  run_qemu qemu-system-x86_64 \
    -accel kvm -cpu host \
    -smp "$VM_CPUS" -m "$VM_MEM_MB" \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -drive "file=$SEED,if=virtio,format=raw,readonly=on,media=cdrom" \
    -nic "user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:${VM_SSH_PORT}-:22" \
    -display none -daemonize \
    -serial "file:$CONSOLE_LOG" \
    -pidfile "$PIDFILE"
  wait_for_ssh
}

cmd_ssh() {
  is_running || { echo "error: VM not running; run '$0 up'" >&2; exit 1; }
  vm_ssh "$@"
}

cmd_provision() {
  is_running || { echo "error: VM not running; run '$0 up'" >&2; exit 1; }
  local mise_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/mise"
  echo ">> copying provision/mise into the VM"
  tar -C "$(dirname "$mise_dir")" -cf - mise | vm_ssh "tar -xf - -C /home/${SSH_USER}"
  echo ">> running bootstrap.sh (full systemd — snap/flatpak/docker included)"
  vm_ssh "cd ~/mise && ./bootstrap.sh"
}

cmd_console() {
  tail -n 50 -f "$CONSOLE_LOG"
}

cmd_down() {
  if ! is_running; then
    echo ">> VM not running"
    return 0
  fi
  echo ">> powering off"
  vm_ssh "sudo poweroff" 2>/dev/null || kill "$(cat "$PIDFILE")" 2>/dev/null || true
  for _ in $(seq 1 20); do
    is_running || break
    sleep 1
  done
  is_running && kill -9 "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
}

cmd_clean() {
  cmd_down
  rm -rf "$CACHE_DIR"
  echo ">> cache removed"
}

case "${1:-}" in
  up) cmd_up ;;
  ssh) shift; cmd_ssh "$@" ;;
  provision) cmd_provision ;;
  console) cmd_console ;;
  down) cmd_down ;;
  clean) cmd_clean ;;
  *)
    sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
