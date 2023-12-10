#!/usr/bin/bash -x

run_packer() {
    echo "Entering Packer"
    if [ -f THAT_IMAGE ]; then
       cluster_ami=$(cat THAT_IMAGE)
       return
    fi
    echo "Running Packer..."
    cd packer
    packer build main.pkr.hcl -machine-readable | tee packer.log
    cluster_ami=$(tail -n1 packer.log | grep -o 'ami-[0-9a-f]*')
    rm packer.log
    cd ..
    echo $cluster_ami>THAT_IMAGE
    echo "Exiting Packer"
}

run_terraform() {
    NUMBER_OF_INSTANCES=$1
    INSTANCE_TYPE=$2
    echo "Entering Terraform"
    cd terraform
    terraform apply -auto-approve -var "cluster_ami=${cluster_ami} cluster_size=${NUMBER_OF_INSTANCES}"
    PUBLIC_HOSTS=$(terraform output -json | jq '.public_ip_addresses.value' | grep \" | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' | paste -s -d ',')
    PRIVATE_HOSTS=$(terraform output -json | jq '.private_dns.value' | grep \" | sed 's/"//g' | sed 's/,//g' | sed 's/ //g' | paste -s -d ',')
    HOSTS_SIZE=$(terraform output -json | jq '.private_dns.value | length' )
    if [ $HOSTS_SIZE -eq 1 ]; then
	PRIVATE_HOSTS=$PRIVATE_HOSTS,
	PUBLIC_HOSTS=$PUBLIC_HOSTS,
    fi
    echo PRIVATE_HOSTS=${PRIVATE_HOSTS}
    LUSTRE_DNS_NAME=$(terraform output -json | jq '.lustre_dns_name.value')
    LUSTRE_MOUNT_NAME=$(terraform output -json | jq '.lustre_mount_name.value')
    cd ..

    echo "Exiting Terraform"
}

run_ansible() {
    echo "Entering Ansible"
    cd ansible
    ANSIBLE_SSH_ARGS="-o ServerAliveInterval=5 -o ServerAliveCountMax=1" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "${PUBLIC_HOSTS}" main.yml --key-file="~/.ssh/id_ed25519" --user ec2-user --extra-vars "dns_name=${LUSTRE_DNS_NAME} mount_name=${LUSTRE_MOUNT_NAME} config_name=h123"
    cd ..
    echo "Exiting Ansible"
}

prepare_cluster() {
    NUMBER_OF_INSTANCES=$1
    run_packer
    run_terraform $NUMBER_OF_INSTANCES
    firstMachine=$(echo $PUBLIC_HOSTS | sed 's/,/\n/g' | head -n1)   
}

main() {
    # Lendo os parâmetros dos arquivos
    HOSTS_SIZE_FILE="parametros_instancias.txt"
    INSTANCE_SIZE_FILE="parametros_tamanho_instancia.txt"
    FILE_SIZE_FILE="parametros_tamanho_arquivo.txt"
    SLICE_SIZE_FILE="parametros_tamanho_slice_lustre.txt"
    TEST_TYPE_FILE="parametros_tipo_teste.txt"

    # Iterando sobre as linhas de cada arquivo
    while IFS= read -r HOSTS_SIZE && IFS= read -r INSTANCE_SIZE; do
        prepare_cluster "$HOSTS_SIZE" "$INSTANCE_SIZE"

        while IFS= read -r FILE_SIZE && IFS= read -r SLICE_SIZE && IFS= read -r TEST_TYPE; do
            run_ansible "$FILE_SIZE" "$SLICE_SIZE" "$TEST_TYPE"
            bash -x ./runMpi.sh "$firstMachine" "$PRIVATE_HOSTS" "$HOSTS_SIZE"
        done < "$FILE_SIZE_FILE" < "$SLICE_SIZE_FILE" < "$TEST_TYPE_FILE"
    done < "$HOSTS_SIZE_FILE" < "$INSTANCE_SIZE_FILE"
}

main() {
    prepare_cluster
    run_ansible
    bash -x ./runMpi.sh $firstMachine $PRIVATE_HOSTS $HOSTS_SIZE
}

main
