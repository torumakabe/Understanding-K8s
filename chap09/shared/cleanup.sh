#!/bin/bash

CHAP="ch09"

# Destroy Shared Resources
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-shared" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure

terraform destroy -auto-approve
RET=$?

# Delete Resource Group for Remote State
RESOURCE_GROUP_NAME=${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-tfstate-rg
[ ${RET} -eq 0 ] && az group delete -n $RESOURCE_GROUP_NAME -y