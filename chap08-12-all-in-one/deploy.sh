#!/bin/bash

# Deploy Shared Resources
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-shared" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./shared

terraform apply -auto-approve ./shared

# Deploy AKS Clster (Blue)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-cluster-blue" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./cluster-blue

terraform apply -auto-approve ./cluster-blue

# Deploy Misc Resources (Blue)
az aks get-credentials -g ${TF_VAR_k8sbook_prefix}-k8sbook-aio-rg -n ${TF_VAR_k8sbook_prefix}-k8sbook-aio-aks-blue --overwrite-existing --admin

terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-misc-blue" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./misc-blue

terraform apply -auto-approve ./misc-blue

# Deploy AKS Clster (Green)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-cluster-green" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./cluster-green

terraform apply -auto-approve ./cluster-green

# Deploy Misc Resources
az aks get-credentials -g ${TF_VAR_k8sbook_prefix}-k8sbook-aio-rg -n ${TF_VAR_k8sbook_prefix}-k8sbook-aio-aks-green --overwrite-existing --admin

terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}aiotfstate" \
    -backend-config="container_name=tfstate-misc-green" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./misc-blue

terraform apply -auto-approve ./misc-green