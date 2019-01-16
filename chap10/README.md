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

## 実行の前に

* prep/deploy/cleanupスクリプト実行が途中終了した場合、環境変数を確認のうえ再実行してください
  * Terraform 既知の不具合
    * [認証トークンのリフレッシュに失敗することがある](https://github.com/terraform-providers/terraform-provider-azurerm/issues/2602)
    * [Azure AD関連リソースの複製を待ちきれない](https://github.com/terraform-providers/terraform-provider-azuread/issues/4)
      * Azure ADの管理オブジェクトはデータセンター間で[非同期に複製](https://docs.microsoft.com/ja-jp/azure/active-directory/fundamentals/active-directory-architecture)されています
      * 参照はネットワーク的に近いAzure ADへ向かうため、リソース作成直後の問い合わせに複製が間に合わないことがあります
      * Terraformコミュニティで対処方針は議論中です
      * provisionerに回避ロジックを入れています
        * Terraformから問い合わせを受けるリソースは、Azure CLIでリソース作成完了を確認してから完了
        * Azureのリソースプロバイダーから問い合わせを受けるリソースは、30秒スリープしてから完了
  * ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています

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

__このサンプルのTerraformとbashスクリプトは環境変数を使います。セッションを中断した/切れてしまった場合には、上記2つのスクリプトを再実行してください。冪等なので再実行可能です__

## 共有リソース作成

作業ディレクトリは引き続き chap10/shared です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成

作業ディレクトリを chap10/cluster-blue に変更し、クラスター"blue"を作成します。

Kubernetesのバージョンは1.11.5です。chap10/modules/cluster-blue/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中で定義しています。


```
cd ../cluster-blue
./deploy.sh
```

作業ディレクトリを chap10/cluster-green に変更し、クラスター"green"を作成します。

Kubernetesのバージョンは1.11.5です。chap10/modules/cluster-green/main.tfのリソース "azurerm_kubernetes_cluster" "aks"の中でで定義しています。
この章のテーマの通り、他バージョンに変更してみてください。利用可能なバージョンは以下のコマンドで取得できます。

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

演習が終わったら、リソースを削除します。カレントディレクトリはch10/cluster-blueを想定していますが、適宜読み替えてください。

```
./cleanup.sh
cd ../cluster-green
./cleanup.sh
cd ../shared
./cleanup.sh
```