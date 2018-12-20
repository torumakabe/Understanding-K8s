# CH08

## 作成リソース概要

![CH08](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch08.jpg?raw=true "CH08")

* Shared Group
  * Resource Group (for Ch08 Resources)
  * Cosmos DB
  * Traffic Manager Profile
  * Storage Account (for Terraform Remote State)
* Cluster Group
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster * 2 (primary/secondary)
  * Kubernetes Resources
    * Sample To-Do Application Service
    * Sample To-Do Application Deployment
    * Cosmos DB Secret for Sample To-Do Application
  * Traffic Manager Endpoint

## 準備

作業ディレクトリの起点をchap08とします。

```
cd $YOURCURRENTDIR/chap08
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

作業ディレクトリは引き続き chap08/shared です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成

作業ディレクトリを chap08/cluster に変更し、クラスターを作成します。

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

* Traffic Manager プロファイル DNS名でアクセスし、ToDoアプリが使えることを確認
* Traffic Manager エンドポイント (Promary/Failover) それぞれ個別にアクセスできることを確認
* PrimaryのServiceを削除し、フェイルオーバーするか確認 (検知時間 + ブラウザキャッシュなどでFailoverには数十秒かかる)

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリはch08/clusterを想定していますが、適宜読み替えてください。

```
./cleanup.sh
cd ../shared
./cleanup.sh
```

## 補足

* セッション切れや認証トークンの有効期限切れなどでdeploy/cleanupスクリプト実行が途中終了した場合、環境変数を確認のうえ再実行してください
  * 可用性が求められるシステムでは、サーバー上でのTerraform実行をおすすめします
  * Azure VM上では、Azure CLI認証に頼らないAzure Managed Identity認証も可能です
* サービスプリンシパルのAzure ADリージョン間複製は非同期に行われるため、作成後nullリソースで90秒待っています
  * もし同期がAKSクラスター作成までに間に合わずエラーになった場合、再実行してください