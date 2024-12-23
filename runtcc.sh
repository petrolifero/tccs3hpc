#!/usr/bin/bash -x

set -e

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
#    NUMBER_OF_INSTANCES=$1
#    INSTANCE_TYPE=$2
#    WORKSPACE=$3
#    ISFSX=$4
#    ISS3=$5
    configsFile=$1
    echo "Entering Terraform"
    cd terraform
    cd lambdaDestroyWorkspace
    zip -r9 ../lambda_function.zip .
    cd ..
    cd lambdaDestroyWorkspaceLayerTerraform
    zip -r9 ../lambda_terraform_layer_function.zip .
    cd ..
#    terraform workspace new $WORKSPACE || true
#    terraform workspace select $WORKSPACE
    terraform apply -auto-approve -var "cluster_ami=${cluster_ami}" -var "config=$(cat $configsFile)"
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
    S3_ENDPOINT=$(terraform output -json | jq '.s3_endpoint.value')
    cd ..

    echo "Exiting Terraform"
}

run_ansible() {
    OBJECT_SIZE=$1
    MODE=$2
    isFSX=$3
    isS3=$4
    S3_ENDPOINT=$5
    echo "Entering Ansible"
    cd ansible
    ANSIBLE_SSH_ARGS="-o ServerAliveInterval=5 -o ServerAliveCountMax=1" ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "${PUBLIC_HOSTS}" main.yml --key-file="~/.ssh/id_ed25519" --user ec2-user --extra-vars "dns_name=${LUSTRE_DNS_NAME} mount_name=${LUSTRE_MOUNT_NAME} config_name=h123 object_size=${OBJECT_SIZE} isFSX=${isFSX} S3_ENDPOINT=${S3_ENDPOINT}"
    cd ..
    echo "Exiting Ansible"
}

prepare_cluster() {
#    NUMBER_OF_INSTANCES=$1
#    INSTANCE_TYPE=$2
#    OBJECT_SIZE=$3
#    MODE=$4
#    WORKSPACE=${OBJECT_SIZE}-${MODE}-my-new-workspace
    run_packer
#   isFSX=false
#   isS3=false
#    if [[ "$MODE" == *fsx* ]]; then
#	isFSX=true
#    else
#	isS3=true
#    fi
    run_terraform "../configs.json" #$NUMBER_OF_INSTANCES $INSTANCE_TYPE $WORKSPACE $isFSX $isS3
#    firstMachine=$(echo $PUBLIC_HOSTS | sed 's/,/\n/g' | head -n1)   
}

main() {
    #object size = 10B 100B 1KB 10KB 100KB 1MB 10MB 100MB
    #S3 or FSX
    #on FSX, two ways : default config and optimazed
    >THAT_MACHINE.LOG
#    for object_size in 10 100 1000 10000 100000 1000000 10000000 100000000
#    do
#	for mode in fsx s3 fsxOptimal
#	do
#	    for fsxPerformance in 1 10 100 1000 10000 100000 1000000
#	    do
#		prepare_cluster 3 t3.nano $object_size $mode
#		run_ansible $object_size $mode $isFSX $isS3 ${S3_ENDPOINT}
#		bash -x ./runMpi.sh $firstMachine $PRIVATE_HOSTS $HOSTS_SIZE $isFSX $isS3
#	    done
#        done
    #    done
    prepare_cluster
}

main
