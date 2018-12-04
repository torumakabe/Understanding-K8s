#!/bin/bash

CHAP="aio"

# Deploy Shared Resources
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-shared" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./shared

terraform apply -auto-approve ./shared

# Deploy AKS Clster (Blue)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-cluster-blue" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./cluster-blue

terraform apply -auto-approve ./cluster-blue

KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-blue-primary-config kubectl apply -f ./sampleapp.yaml
KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-blue-failover-config kubectl apply -f ./sampleapp.yaml


# Deploy AKS Clster (Green)
terraform init \
    -backend-config="storage_account_name=${TF_VAR_k8sbook_prefix}${CHAP}tfstate" \
    -backend-config="container_name=tfstate-cluster-green" \
    -backend-config="key=terraform.tfstate" \
    -reconfigure \
    ./cluster-green

terraform apply -auto-approve ./cluster-green

KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-primary-config kubectl apply -f ./sampleapp.yaml
KUBECONFIG=~/.kube/${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-aks-green-failover-config kubectl apply -f ./sampleapp.yaml