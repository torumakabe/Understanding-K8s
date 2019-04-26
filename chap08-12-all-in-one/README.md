# All in One

設計方針、テスト済み環境はリポジトリ全体の[README](https://github.com/ToruMakabe/Understanding-K8s)をご覧ください。

## 作成リソース概要

![AIO](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch-aio.jpg?raw=true "AIO")

__8章から12章まですべての演習が可能な環境を作りますが、その分リソースを多く使うのでご注意ください__

### Azure AD認証を試す場合

* Shared Group
  * Resource Group (for AIO Resources)
  * Cosmos DB
  * Traffic Manager Profile
  * Azure RBAC Role Assignment (AKS User Role for Deveploer)
  * Log Analytics Workspace
  * Log Analytics Container Solution
  * Azure Monitor Action Group (email)
  * Storage Account (for Terraform Remote State)
* Cluster Group *2 (blue/green)
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster * 2 (primary/secondary)
    * Azure AD Auth enabled
    * Azure Monitor for Container enabled
  * Kubernetes Resources
    * Sample To-Do Application Service
    * Sample To-Do Application Deployment
    * Cosmos DB Secret for Sample To-Do Application
    * Secret for Cluster Autoscaler
  * Traffic Manager Endpoint
  * Metric Alert (Pending Pods)

### Azure AD認証を試さない場合

* Shared Group
  * Resource Group (for AIO Resources)
  * Cosmos DB
  * Traffic Manager Profile
  * Azure RBAC Role Assignment (AKS User Role for Deveploer)
  * Log Analytics Workspace
  * Log Analytics Container Solution
  * Azure Monitor Action Group (email)
  * Storage Account (for Terraform Remote State)
* Cluster Group *2 (blue/green)
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster * 2 (primary/secondary)
    * Azure Monitor for Container enabled
  * Kubernetes Resources
    * Sample To-Do Application Service
    * Sample To-Do Application Deployment
    * Cosmos DB Secret for Sample To-Do Application
    * Secret for Cluster Autoscaler
  * Traffic Manager Endpoint
  * Metric Alert (Pending Pods)

## 注意事項

* マルチリージョン構成などでリソース作成、データ複製に時間がかかった場合、Terraformがそれをうまく扱えずエラーとなることがあります
* ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています
* [既知の不具合][link_known_issue] に原因と対策、改善の見通しをまとめたので再実行の前にご確認ください

[link_known_issue]: https://github.com/ToruMakabe/Understanding-K8s/blob/master/README.md#known_issue

## この章の対象ディレクトリ

```
.
├── chap08-12-all-in-one
│   ├── README.md (いまここ)
│   ├── cluster-blue (AKSリソースHCLとヘルパースクリプト - Blue)
│   ├── cluster-blue-aad (AKSリソースHCLとヘルパースクリプト - Blue & Azure AD認証)
│   ├── cluster-green (AKSリソースHCLとヘルパースクリプト - Green)
│   ├── cluster-green-aad (AKSリソースHCLとヘルパースクリプト - Green & Azure AD認証)
│   ├── modules (TerraformモジュールHCL)
│   ├── shared (All in One共有リソースHCLとヘルパースクリプト)
│   └── shared-aad (All in One共有リソースHCLとヘルパースクリプト - Azure AD認証)
└── shared
    ├── app (サンプルTODOアプリ)
    └── env (環境変数設定スクリプト)
```

## 準備

作業ディレクトリの起点をchap08-12-all-in-oneとします。

```
cd chap08-12-all-in-one
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

作業ディレクトリは引き続き chap08-12-all-in-one/shared もしくは chap08-12-all-in-one/shared-aad です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成 

作業ディレクトリを chap08-12-all-in-one/cluster-blue もしくは chap08-12-all-in-one/cluster-blue-aad に変更し、クラスター"blue"を作成します。

Kubernetesのバージョンは1.11.9としました。chap08-12-all-in-on/modules/cluster-blue/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中で定義しています。

```
cd ../cluster-blue
./deploy.sh
```

作業ディレクトリを chap08-12-all-in-one/cluster-green もしくは chap08-12-all-in-one/cluster-green-aad に変更し、クラスター"green"を作成します。

Kubernetesのバージョンは1.11.9としました。 chap08-12-all-in-one/modules/cluster-green/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中で定義しています。
10章のテーマの通り、新バージョンがリリースされたら変更してみてください。利用可能なバージョンは以下のコマンドで取得できます。


```
az aks get-versions -l japaneast
```

なお、バージョンアップによってTerraform HCLのオプションに変更があるかもしれません。バージョンを上げる場合にはドキュメントを確認しましょう。

[azurerm_kubernetes_cluster](https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html)

[CHANGELOG](https://github.com/terraform-providers/terraform-provider-azurerm/blob/master/CHANGELOG.md)

```
cd ../cluster-green
./deploy.sh
```

これで環境が作成できました。クラスターを操作するには、各クラスターのcredentialを都度入手してください。~/.kube/configを汚したくない場合は、credentialを-fオプションでファイルに出力できます。

[Azure CLI - az aks get-credentials](https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-get-credentials)

```
az aks get-credentials -g YOUR-RESOURCE-GROUP -n YOUR-CLUSTER -a -f
```

## 演習例

* 書籍の手順を参考に
* 他章のREADMEを参考に

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリは chap08-12-all-in-one/cluster-blueを想定していますが、適宜読み替えてください。
cluster-green-aad、cluster-blue-aad、shared-aadを使った方は、ご注意を。

なお、Azure AD認証クラスターで演習を行った場合、現在Azure CLIでログインしているユーザーを確認してください。TerraformはAzure CLIの認証情報を使います。Azureリソースを操作する権限がないユーザーだと、以降の削除ができません。
もし権限のないユーザーであれば、az loginで権限のあるユーザーとしてログインし、念のためサブスクリプションを確認してください。

```
./cleanup.sh
cd ../cluster-green
./cleanup.sh
cd ../shared
./cleanup.sh
```