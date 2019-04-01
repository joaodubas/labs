# terraform/ansible provisioner

To make easier the task of provisioning my remote development machine, on DigitalOcean, I created a terraform script and
a series of ansible playbooks, to do the hard work.

Besides that, I have a docker image, and compose file, that already have installed:

1. terraform 0.11.11
2. docker-machine 0.16.0
3. docker-compose 18.09.1
4. ansible 2.7.6

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
ansible-playbook -i inventory/digital_ocean.py <path-to-playbook>
```
