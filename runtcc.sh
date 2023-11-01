#!/usr/bin/bash



cd packer
packer build main.pkr.hcl -machine-readable | tee packer.log
cluster_ami=$(tail -n1 packer.log | grep -o 'ami-[0-9a-f]*')
rm packer.log

cd ../terraform
terraform destroy -auto-approve
terraform apply -auto-approve -var "cluster_ami=${cluster_ami}"
HOSTS=$(terraform output -json | jq '.public_ip_addresses.value' | grep \" | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' | paste -s -d ',')
LUSTRE_DNS_NAME=$(terraform output -json | jq '.lustre_dns_name.value')
LUSTRE_MOUNT_NAME=$(terraform output -json | jq '.lustre_mount_name.value')

cd ../ansible
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$HOSTS" main.yml --key-file="~/.ssh/id_ed25519" --user ec2-user --extra-vars "dns_name=${LUSTRE_DNS_NAME} mount_name=${LUSTRE_MOUNT_NAME} HOSTS=${HOSTS}"

