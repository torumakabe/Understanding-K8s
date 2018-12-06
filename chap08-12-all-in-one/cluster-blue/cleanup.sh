#!/bin/bash

CHAP="aio"

# Destroy AKS Clster (Blue)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-cluster-blue" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure

terraform destroy -auto-approve

# Delete Kubetenetes config
rm ~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-blue-primary-config
rm ~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-blue-failover-config