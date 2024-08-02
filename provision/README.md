# terraform/ansible/comtrya provisioner

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

To provision a local development machine we use [`comtrya`][0] to execute a
series of manifests that install:

1. system dependencies
2. command line utilities
   1. mise
   2. atuin
   3. starship
   4. zoxide
3. user
   1. fish
   2. git
   3. neovim
   4. tmux
   5. tmuxp

To execute it:

```bash
cd /opt/comtrya
comtrya apply
```

To test the manifests we can use the playground service:

```bash
docker compose run --entrypoint bash playground -c bash
```

[0]: https://www.comtrya.dev/
