#!/bin/bash

az aks get-credentials -g ${TF_VAR_k8sbook_prefix}-k8sbook-aio-rg -n ${TF_VAR_k8sbook_prefix}-k8sbook-aio-aks-blue --overwrite-existing --admin

terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-misc-blue" \
    -backend-config="key=terraform.tfstate"

#terraform plan
terraform apply -auto-approve