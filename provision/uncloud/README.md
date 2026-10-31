# Uncloud Multi-Node Lab (`*.internal`)

Declarative local lab for [Uncloud (`uncloud.run`)][uncloud] built with **Terraform**, **QEMU/KVM (`libvirt`)**, **Technitium DNS Server**, and **`mise`**. It works identically on **native Ubuntu Linux** (laptop/desktop) and **Windows + WSL2**.

## Architecture

- **Bridge Network (`br-uncloud` — `10.240.0.0/24`)**: Managed via `dmacvicar/libvirt` in NAT mode (`dns { enabled = false }` so port `53` stays free for Technitium).
- **Technitium DNS Server (`10.240.0.1:53` & `:5380`)**: Managed via `kreuzwerker/docker` and `kenske/technitium`. Hosts the authoritative `internal` Primary zone:
  - `dns.internal` -> `10.240.0.1`
  - `uc-node-1.internal` -> `10.240.0.11`, `uc-node-2.internal` -> `10.240.0.12`, ...
  - `*.internal` -> Multi-IP `A` records pointing to all cluster nodes for automatic Caddy ingress round-robin.
- **Uncloud Cluster Nodes (`uc-node-1..N`)**: Lightweight Ubuntu Cloud-Init KVM VMs with thin Copy-on-Write `qcow2` disks, static Netplan v2 networking, and an isolated Uncloud config at `.cache/uncloud/config.yaml`.
- **Caddy Internal PKI (`local_certs`)**: Global Caddy configuration (`config/Caddyfile.global`) issues TLS certificates from an internal CA shared across all nodes via `caddy.storage.uncloud`.
- **Host Integration**:
  - **Linux / WSL2 (`scripts/host-linux.sh`)**: Configures `systemd-resolved` split-DNS (`~internal` -> `10.240.0.1`), installs Caddy's Root CA into `/usr/local/share/ca-certificates`, and imports it into browser NSS databases (`~/.pki/nssdb`, Firefox/Zen profiles) via `certutil`.
  - **Windows Host (`scripts/host-access.ps1`)**: When running inside WSL2, imports Caddy's Root CA into `Cert:\CurrentUser\Root`, adds a Windows NRPT split-DNS rule for `.internal` -> `10.240.0.1`, and adds a route for `10.240.0.0/24` via the WSL2 VM IP.

## Quickstart (Ubuntu Laptop or inside WSL2)

From `provision/uncloud`:

```bash
# 1. Provision the bridge network, Technitium DNS, KVM VMs, Uncloud cluster, and Root CA trust
mise run up

# 2. Deploy the sample 2-replica whoami service (exposes https://whoami.internal & http://whoami.internal)
mise run deploy-demo

# 3. (Optional) Deploy the Gitea + Chadburn + Renovate stack from ../../gitea/docker-compose.yml
mise run deploy-gitea

# 4. Check cluster & DNS status
mise run status

# 5. Verify HTTPS and HTTP ingress
curl -I https://whoami.internal
curl -I https://gitea.internal
```

### Extra Step on Windows + WSL2

When running inside WSL2, `mise run up` automatically imports the Root CA into your Windows user certificate store and attempts to configure the Windows NRPT DNS rule and route. Because Windows requires **Administrator** privileges for NRPT and route changes, run the following once in an **elevated PowerShell** on Windows:

```powershell
pwsh -ExecutionPolicy Bypass -File .\provision\uncloud\scripts\host-access.ps1 -Action Up
```

Once applied, open any browser on Windows or Ubuntu and visit:
- **`https://whoami.internal`** (or `http://whoami.internal`) — load-balanced across `uc-node-1` and `uc-node-2`
- **`https://gitea.internal`** — Gitea web interface (when deployed via `mise run deploy-gitea`)
- **`http://dns.internal:5380`** — Technitium DNS Web Console (default credentials: `admin` / `uncloud-lab-admin`)

## Deploying Services Outside `provision/uncloud` (e.g., `gitea/docker-compose.yml`)

Services do not need to live inside `provision/uncloud`. For example, [`../../gitea/docker-compose.yml`](../../gitea/docker-compose.yml) lives in its own top-level folder and works with **both** local `docker compose up` and `uc deploy`:

1. **`x-ports` and `x-machines` alongside `ports`**:
   Docker Compose ignores `x-*` extensions, while Uncloud uses `x-ports` (exposing `gitea.internal:3000/https`, `/http`, and `222:22/tcp@host`) and `x-machines` (pinning stateful volumes and co-locating `cron` + `renovate` on `uc-node-1`).
2. **File-based `configs:` instead of directory bind mounts**:
   [`gitea/docker-compose.yml`](../../gitea/docker-compose.yml) references `./config/cron/config.ini` and `./config/renovate/config.js` via top-level `configs:` (`file: ./config/...`). Local Docker Compose mounts them as files, and `uc deploy` automatically uploads them to the remote VM containers without needing manual `scp`/`rsync`.
3. **Default compose network**:
   Omitting custom `networks:` blocks lets local Docker Compose use its default project network while allowing Uncloud to attach the containers to its cluster-wide WireGuard/DNS mesh.

You can deploy it either from `provision/uncloud` (`mise run deploy-gitea` / `uc deploy -f ../../gitea/docker-compose.yml`) or directly from `gitea/` by pointing `UNCLOUD_CONFIG` to the lab config.

## Scaling & Customization

You can adjust the number of VM nodes or resources via Terraform variables:

```bash
# Scale the cluster from 2 to 3 VM nodes
terraform -chdir=terraform apply -var="vm_count=3"
```

All configurable variables (`vm_count`, `vm_vcpu`, `vm_memory_mb`, `vm_disk_gb`, `ubuntu_release`, `subnet_cidr`, `dns_admin_password`) are documented in [`terraform/variables.tf`](./terraform/variables.tf).

## Using `uc` Directly

Because `mise.toml` sets `UNCLOUD_CONFIG = "{{config_root}}/.cache/uncloud/config.yaml"`, any `uc` command run inside `provision/uncloud` (with `mise` active) automatically targets the lab cluster:

```bash
uc machine ls
uc ls
uc caddy config
```

## Teardown

```bash
# Destroy VMs, libvirt network, Technitium container, and host DNS/CA configuration
mise run down

# Full reset (also deletes cached cloud image and state in .cache/)
mise run clean
```

[uncloud]: https://uncloud.run/
