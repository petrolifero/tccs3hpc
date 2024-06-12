#!/usr/bin/bash


workspaces=$(terraform workspace list | grep -v default | sed 's/*//g' )
for i in $workspaces; do echo $i; terraform workspace select $i; terraform destroy -auto-approve; terraform workspace select default; terraform workspace delete $i; done
