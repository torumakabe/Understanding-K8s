# CH10

設計方針、テスト済み環境はリポジトリ全体の[README](https://github.com/ToruMakabe/Understanding-K8s)をご覧ください。

## 作成リソース概要

![CH10](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch10.jpg?raw=true "CH10")

* Shared Group
  * Resource Group (for Ch10 Resources)
  * Cosmos DB
  * Traffic Manager Profile
  * Storage Account (for Terraform Remote State)
* Cluster Group *2 (blue/green)
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster
  * Kubernetes Resources
    * Sample To-Do Application Service
    * Sample To-Do Application Deployment
    * Cosmos DB Secret for Sample To-Do Application
  * Traffic Manager Endpoint

## 注意事項

* マルチリージョン構成などでリソース作成、データ複製に時間がかかった場合、Terraformがそれをうまく扱えずエラーとなることがあります
* ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています
* [既知の不具合][link_known_issue] に原因と対策、改善の見通しをまとめたので再実行の前にご確認ください

[link_known_issue]: https://github.com/ToruMakabe/Understanding-K8s/blob/master/README.md#known_issue

## この章の対象ディレクトリ

```
.
├── chap10
│   ├── README.md (いまここ)
│   ├── cluster-blue (AKSリソースHCLとヘルパースクリプト - Blue)
│   ├── cluster-green (AKSリソースHCLとヘルパースクリプト - Green)
│   ├── modules (TerraformモジュールHCL)
│   ├── shared (chap10共有リソースHCLとヘルパースクリプト)
│   └── (Kubernetesマニフェスト)
└── shared
    ├── app (サンプルTODOアプリ)
    └── env (環境変数設定スクリプト)
```

## 準備

作業ディレクトリの起点をchap10とします。

```
cd chap10
```

環境変数を設定するスクリプト(../shared/env/sample_set_env.sh)を編集します。各変数の詳細はスクリプトに記述しました。
編集したら、実行します。環境変数にセットしたいため、sourceを忘れずに。

```
source ../shared/env/sample_set_env.sh
```

TerraformのStateを保管するストレージアカウントを作成します。キーを環境変数に入れるため、sourceを忘れずに。

```
cd shared
source ./prep.sh
```

__このサンプルのTerraformとbashスクリプトは環境変数を使います。以降の手順でセッションを中断した/切れてしまった場合には、上記2つのスクリプトを再実行してください。冪等なので再実行可能です__

## 共有リソース作成

作業ディレクトリは引き続き chap10/shared です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成

作業ディレクトリを chap10/cluster-blue に変更し、クラスター"blue"を作成します。

Kubernetesのバージョンは1.11.9としました。chap10/modules/cluster-blue/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中で定義しています。


```
cd ../cluster-blue
./deploy.sh
```

作業ディレクトリを chap10/cluster-green に変更し、クラスター"green"を作成します。

Kubernetesのバージョンは1.11.9としました。chap10/modules/cluster-green/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中で定義しています。
この章のテーマの通り、新バージョンがリリースされたら変更してみてください。利用可能なバージョンは以下のコマンドで取得できます。

```
az aks get-versions -l japaneast
```

なお、KubernetesのバージョンアップによってTerraform HCLのオプションに変更があるかもしれません。バージョンを上げる場合にはドキュメントを確認しましょう。

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

* Azureポータルで作成したTraffic Managerプロファイルを確認します
* Traffic ManagerプロファイルのDNS名にブラウザでアクセスし、サンプルToDoアプリの動作を確認します
  * 優先度の高いblue(優先度100)にルーティングされます 
* blue、greenそれぞれのエンドポイントにアクセスし、それぞれのクラスターでServiceが動いていることを確認します
  * エンドポイントはプロファイルの画面からたどれます
* greenに違うバージョンのKubernetesを導入しても、ToDoアプリの動作に問題がないことを確認します
  * 余裕があればkubectlでPodなどリソースの状態を確認します
* エンドポイントの優先度を変更し、トラフィックをgreenに向けます
  * chap10/cluster-blue/main.tfのtraffic_manager_endpoint_priorityを300にし、再度 ./deploy.shを実行します
  * 優先度のローテーション方法は多様ですが、greenを固定し、blueを動かすのがシンプルなやり方です
* Traffic ManagerプロファイルのDNS名にアクセスし、問題なく動いていることを確認します

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリはchap10/cluster-blueを想定していますが、適宜読み替えてください。

```
./cleanup.sh
cd ../cluster-green
./cleanup.sh
cd ../shared
./cleanup.sh
```