# terraform/ansible provisioner

To make easier the task of provisioning my remote development machine, on DigitalOcean, I created a terraform script and
a series of ansible playbooks, to do the hard work.

Besides that, I have a docker image, and compose file, that already have installed:

1. terraform 1.5.7
2. docker 24.06
3. docker-compose 2.21.0
4. ansible-core 2.15.3
5. ansible 8.3.0

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
