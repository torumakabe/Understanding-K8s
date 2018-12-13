#!/bin/bash

CHAP="aio"

terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-cluster-green" \
    -backend-config="key=terraform.tfstate"  

terraform apply -auto-approve

# KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-primary-config kubectl apply -f ../todoapp.yaml
# KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-failover-config kubectl apply -f ../todoapp.yaml