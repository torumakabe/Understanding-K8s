#!/bin/bash

CHAP="aio"

# Destroy AKS Clster (Green)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-cluster-green" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./cluster-green

terraform destroy -auto-approve ./cluster-green

# Delete Kubetenetes config
rm ~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-primary-config
rm ~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-failover-config