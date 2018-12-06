#!/bin/bash

CHAP="aio"

RESOURCE_GROUP_NAME=${TF_VAR_k8sbook_prefix}-k8sbook-${CHAP}-tfstate-rg
STORAGE_ACCOUNT_NAME=${TF_VAR_k8sbook_prefix}${CHAP}tfstate
CONTAINER_NAME_SHARED=tfstate-shared
CONTAINER_NAME_CLUSTER_BLUE=tfstate-cluster-blue
CONTAINER_NAME_CLUSTER_GREEN=tfstate-cluster-green

az group create --name $RESOURCE_GROUP_NAME --location japaneast

az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

export ARM_ACCESS_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

az storage container create --name ${CONTAINER_NAME_SHARED} --account-name $STORAGE_ACCOUNT_NAME --account-key $ARM_ACCESS_KEY
az storage container create --name ${CONTAINER_NAME_CLUSTER_BLUE} --account-name $STORAGE_ACCOUNT_NAME --account-key $ARM_ACCESS_KEY
az storage container create --name ${CONTAINER_NAME_CLUSTER_GREEN} --account-name $STORAGE_ACCOUNT_NAME --account-key $ARM_ACCESS_KEY