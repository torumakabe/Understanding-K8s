# CH11

設計方針、テスト済み環境はリポジトリ全体の[README](https://github.com/ToruMakabe/Understanding-K8s)をご覧ください。

## 作成リソース概要

![CH11](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch11.jpg?raw=true "CH11")

### Azure AD認証を試す場合

* Shared Group
  * Resource Group (for CH11 Resources)
  * Azure RBAC Role Assignment (AKS User Role for Deveploer)
  * Storage Account (for Terraform Remote State)
* Cluster Group
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster
    * Azure AD Auth enabled

### Azure AD認証を試さない場合

* Shared Group
  * Resource Group (for CH11 Resources)
  * Storage Account (for Terraform Remote State)
* Cluster Group
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster

## 注意事項

* マルチリージョン構成などでリソース作成、データ複製に時間がかかった場合、Terraformがそれをうまく扱えずエラーとなることがあります
* ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています
* [既知の不具合][link_known_issue] に原因と対策、改善の見通しをまとめたので再実行の前にご確認ください

[link_known_issue]: https://github.com/ToruMakabe/Understanding-K8s/blob/master/README.md#known_issue

## この章の対象ディレクトリ

```
.
├── chap11
│   ├── README.md (いまここ)
│   ├── cluster (AKSリソースHCLとヘルパースクリプト)
│   ├── cluster-aad (AKSリソースHCLとヘルパースクリプト - Azure AD認証)
│   ├── modules (TerraformモジュールHCL)
│   ├── shared (chap11共有リソースHCLとヘルパースクリプト)
│   ├── shared-aad (chap11共有リソースHCLとヘルパースクリプト - Azure AD認証)
│   └── (Kubernetesマニフェスト)
└── shared
    └── env (環境変数設定スクリプト)
```

## 準備

作業ディレクトリの起点をchap11とします。

```
cd chap11
```

環境変数を設定するスクリプト(../shared/env/sample_set_env.sh)を編集します。各変数の詳細はスクリプトに記述しました。
Azure AD認証の有無で設定する変数が変わりますので、ご注意を。

編集したら、実行します。環境変数にセットしたいため、sourceを忘れずに。

```
source ../shared/env/sample_set_env.sh
```

TerraformのStateを保管するストレージアカウントを作成します。キーを環境変数に入れるため、sourceを忘れずに。
Azure AD認証を試す場合、作業ディレクトリはshared-aadです。以降もAzure AD認証の有無をあらわす規則を"-aad"とします。

```
cd shared
source ./prep.sh
```

__このサンプルのTerraformとbashスクリプトは環境変数を使います。以降の手順でセッションを中断した/切れてしまった場合には、上記2つのスクリプトを再実行してください。冪等なので再実行可能です__

## 共有リソース作成

作業ディレクトリは引き続き chap11/shared もしくは chap11/shared-aad です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成

作業ディレクトリを chap11/cluster もしくは chap11/cluster-aad に変更し、クラスターを作成します。

```
cd ../cluster
./deploy.sh
```

これで環境が作成できました。クラスターを操作するには、各クラスターのcredentialを都度入手してください。~/.kube/configを汚したくない場合は、credentialを-fオプションでファイルに出力できます。

[Azure CLI - az aks get-credentials](https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-get-credentials)

```
az aks get-credentials -g YOUR-RESOURCE-GROUP -n YOUR-CLUSTER -a -f
```

## 演習例

* 書籍の手順を参考に
  * Azure AD認証無しのクラスターを作った場合は、Service Accountの演習のみ
    * 書籍11章 "Service AccountとRoleのひも付け"からはじめてください
    * Namespace "k8sbook" を作っていないため、 まず namespace.yaml をapplyして作成してください
    * 節の冒頭でわざとRoleの作成に失敗するくだりがありますが、ここからadmin権限ではじめた場合には失敗しません
      * わざと失敗するのはAzure AD認証から流れで演習した場合です

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリはchap11/clusterを想定していますが、適宜読み替えてください。
cluster-aad、shared-aadを使った方は、ご注意を。

なお、Azure AD認証クラスターで演習を行った場合、現在Azure CLIでログインしているユーザーを確認してください。TerraformはAzure CLIの認証情報を使います。Azureリソースを操作する権限がないユーザーだと、以降の削除ができません。
もし権限のないユーザーであれば、az loginで権限のあるユーザーとしてログインし、念のためサブスクリプションを確認してください。

```
./cleanup.sh
cd ../shared
./cleanup.sh
```