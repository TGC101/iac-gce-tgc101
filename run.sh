#!/bin/bash

echo "Terraform Play Time ~~"
export GOOGLE_APPLICATION_CREDENTIALS=./credentials
export pub=`cat ~/.ssh/id_rsa.pub`
export project=`sed "s/[[:space:]]//g" project`
terraform init -var "key_devops=${pub}" -var "project=${project}"
terraform apply -auto-approve -var "key_devops=${pub}" -var "project=${project}"
echo "CHECK ALL GCE UP..."
while true
do
    ansible all -m ping > /dev/null
    if [[ "$?" == "0" ]] 
    then
        echo "Ansible Play Time ~~"
        break
    fi
done
ansible-playbook playbook.yml
