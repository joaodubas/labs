# terraform/ansible provisioner (remote) + mise bootstrap (local)

To make easier the task of provisioning my remove server machine, on
DigitalOcean, I created a terraform script and a series of ansible playbooks, to
do the hard work.

Besides that, I have a docker image, and compose file, that already have
installed:

1. terraform 1.8.3
2. docker 27.1.1
3. docker-compose 2.29.1
4. ansible-core 2.17.2
5. ansible 10.2.0

## Running the project for remote machines

Using `docker` and `docker-compose` you can do the following steps:

```bash
docker-compose up -d
docker-compose exec ops ash
# inside ops container
cd /opt/terraform
terraform plan
terraform apply
# cd /opt/ansible
ansible-galaxy install -r requirements.yml
ansible-playbook -i inventory/digital_ocean.py <path-to-playbook>
```

### Order of playbooks

1. system
2. tmux
3. pyenv
4. rtx

## Running the project for local machine

Local provisioning uses [mise bootstrap][0]: `provision/mise/` holds the
bootstrap config (`mise.toml` plus the `mise.linux.toml` / `mise.macos.toml`
OS variants), the file tasks under `mise/tasks/<namespace>/<task>` and the
static `files/` tree. The entrypoint installs mise
system-wide if missing, then runs the bootstrap pipeline:

```bash
provision/mise/bootstrap.sh
```

What gets provisioned:

1. system dependencies (apt / Homebrew, docker, flatpak apps, nerd fonts)
2. CLI tools as pinned global mise tools (atuin, starship, zoxide)
3. user environment (fish, git, neovim, tmux, tmuxp) — runtime configs copied
   from a single clone of the [ide][1] repo

### Testing

Two playgrounds exist:

```bash
# container (no systemd — snap/flatpak/docker tasks are smoke-tested only)
docker compose run --entrypoint bash playground
# inside: cd /opt/mise && ./bootstrap.sh

# full-system KVM VM (real systemd; qemu tooling comes from the
# linux:qemu bootstrap task)
provision/vm/vm.sh up
provision/vm/vm.sh provision   # copies provision/mise and runs bootstrap.sh
```

Feasibility analysis, verification procedures and migration notes from the
former comtrya-based setup: `docs/mise-bootstrap-migration.md`.

[0]: https://mise.jdx.dev/bootstrap.html
[1]: https://gitea.dubas.dev/joao.dubas/ide
