#!/usr/bin/bash

calculate_hash() {
    sha256sum packer/main.pkr.hcl | cut -d ' ' -f 1
}

check_existing_ami() {
    local hash="$1"
    local ami_query="Name=tag:build_context_hash,Values=$hash"
    local existing_ami=$(aws ec2 describe-images --filters "$ami_query" --query 'Images[0].ImageId' --output text)

    if [ "$existing_ami" != "None" ]; then
        echo "AMI with hash $hash already exists. Using existing AMI: $existing_ami"
        cluster_ami="$existing_ami"
        return 0
    else
        echo "AMI with hash $hash not found."
        return 1
    fi
}

run_packer() {
    echo "Entering Packer"
    local hash=$(calculate_hash)

    if ! check_existing_ami "$hash"; then
        echo "Running Packer..."
        cd packer
        packer build -var "build_context_hash=$hash" main.pkr.hcl -machine-readable | tee packer.log
        cluster_ami=$(tail -n1 packer.log | grep -o 'ami-[0-9a-f]*')
        rm packer.log
        cd ..
    fi

    echo "Exiting Packer"
}

run_terraform() {
    echo "Entering Terraform"
    cd terraform
    terraform destroy -auto-approve
    terraform apply -auto-approve -var "cluster_ami=${cluster_ami}"
    PUBLIC_HOSTS=$(terraform output -json | jq '.public_ip_addresses.value' | grep \" | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' | paste -s -d ',')
    PRIVATE_HOSTS=$(terraform output -json | jq '.private_dns.value' | grep \" | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' | paste -s -d ',')
    LUSTRE_DNS_NAME=$(terraform output -json | jq '.lustre_dns_name.value')
    LUSTRE_MOUNT_NAME=$(terraform output -json | jq '.lustre_mount_name.value')
    cd ..

    echo "Exiting Terraform"
}

run_ansible() {
    echo "Entering Ansible"
    cd ansible
    ANSIBLE_SSH_ARGS="-o ServerAliveInterval=5 -o ServerAliveCountMax=1" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "${PUBLIC_HOSTS}" main.yml --key-file="~/.ssh/id_ed25519" --user ec2-user --extra-vars "dns_name=${LUSTRE_DNS_NAME} mount_name=${LUSTRE_MOUNT_NAME}"
    ANSIBLE_SSH_ARGS="-o ServerAliveInterval=5 -o ServerAliveCountMax=1" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "${firstMachine}," runmpi.yml --key-file="~/.ssh/id_ed25519" --user ec2-user --extra-vars "HOSTS=${PRIVATE_HOSTS}"
    cd ..

    echo "Exiting Ansible"
}

main() {
    run_packer
    run_terraform
    firstMachine=$(echo $PUBLIC_HOSTS | sed 's/,/\n/g' | head -n1)
    echo firstMachine = $firstMachine
    run_ansible
}

main
