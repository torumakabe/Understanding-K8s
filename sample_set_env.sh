#!/bin/bash

export TF_VAR_k8sbook_prefix="YOUR PREFIX"
export TF_VAR_k8sbook_resource_group_location="japaneast"
export TF_VAR_k8sbook_failover_location="westus2"
export TF_VAR_k8sbook_admin_email_address="ADMIN EMAIL ADDRESS"
export TF_VAR_k8sbook_aad_tenant_id=$(az account show --query tenantId -o tsv)

# For AAD Auth
export TF_VAR_k8sbook_aad_userid_1="YOUR AAD USER"
export TF_VAR_k8sbook_aad_client_app_id="YOUR AAD CLIENT APP ID FOR AAD AUTH"
export TF_VAR_k8sbook_aad_server_app_id="YOUR AAD SERVER APP ID FOR AAD AUTH"
export TF_VAR_k8sbook_aad_server_app_secret="YOUR AAD SERVER APP SECRET FOR AAD AUTH"