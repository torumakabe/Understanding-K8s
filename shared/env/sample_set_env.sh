#!/bin/bash

# あなたのリソースを一意にする接頭辞を考えてください (英数字8文字程度 例: tomakabe99)
export TF_VAR_k8sbook_prefix="YOUR PREFIX"

# あなたのリソースを配置するリージョンを指定してください
export TF_VAR_k8sbook_resource_group_location="japaneast"

# フェイルオーバー先のリージョンを指定してください (8章、オールインワンのみ)
export TF_VAR_k8sbook_failover_location="westus2"

# Azure Monitor のアクションで送信するメールアドレスを指定してください (12章、オールインワンのみ)
export TF_VAR_k8sbook_admin_email_address="ADMIN EMAIL ADDRESS"

# (編集不要) Terraform実行ユーザーがログインしているAzure ADテナントIDを取得します
export TF_VAR_k8sbook_aad_tenant_id=$(az account show --query tenantId -o tsv)


## 以降、Azure AD認証を試したい場合のみ
## まずは次の記事を参考に、Azure AD認証用アプリケーション登録を行ってください (https://docs.microsoft.com/ja-jp/azure/aks/aad-integration)

# Azure AD認証を試したいユーザーのオブジェクトIDを指定します。認証にAKSクラスターが属するものとは別のAzure ADを使いたい場合はゲスト登録を行い、ゲストとしてのオブジェクトIDを指定してください
export TF_VAR_k8sbook_aad_userid_1="YOUR AAD USER"

# 認証にAKSクラスターが属するのとは別のAzure ADを使いたい場合は指定します。空にするとAKSクラスターが属するAzure ADテナントが使われます
export TF_VAR_k8sbook_aad_ext_tenant_id="YOUR AAD ENTERNAL TENANT ID FOR AAD AUTH"

# AKS認証用 Azure AD クライアントアプリケーションIDを設定してください
export TF_VAR_k8sbook_aad_client_app_id="YOUR AAD CLIENT APP ID FOR AAD AUTH"

# AKS認証用 Azure AD サーバーアプリケーションIDを設定してください
export TF_VAR_k8sbook_aad_server_app_id="YOUR AAD SERVER APP ID FOR AAD AUTH"

# AKS認証用 Azure AD サーバーアプリケーションシークレット(キー)を設定してください
export TF_VAR_k8sbook_aad_server_app_secret="YOUR AAD SERVER APP SECRET FOR AAD AUTH"
