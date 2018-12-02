#!/bin/bash

terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-cls-green" \
    -backend-config="key=terraform.tfstate"

#terraform plan
terraform apply -auto-approve