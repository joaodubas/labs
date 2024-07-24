# terraform/ansible provisioner

To make easier the task of provisioning my remote development machine, on DigitalOcean, I created a terraform script and
a series of ansible playbooks, to do the hard work.

Besides that, I have a docker image, and compose file, that already have installed:

1. terraform 1.8.3
2. docker 27.0.3
3. docker-compose 2.29.0
4. ansible-core 2.17.2
5. ansible 10.2.0

## Running the project

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
