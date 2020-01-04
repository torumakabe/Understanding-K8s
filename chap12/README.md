# CH12

設計方針、テスト済み環境はリポジトリ全体の[README](https://github.com/ToruMakabe/Understanding-K8s)をご覧ください。

## 作成リソース概要

![CH12](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch12.jpg?raw=true "CH12")

* Shared Group
  * Resource Group (for CH12 Resources)
  * Log Analytics Workspace
  * Log Analytics Container Solution
  * Azure Monitor Action Group (email)
  * Storage Account (for Terraform Remote State)
* Cluster Group
  * Service Principal (for AKS Cluster)
    * Role Assignment
    * Password
  * AKS Cluster
    * Azure Monitor for Container enabled
  * Metric Alert (Pending Pods)

## 注意事項

* マルチリージョン構成などでリソース作成、データ複製に時間がかかった場合、Terraformがそれをうまく扱えずエラーとなることがあります
* ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています
* [既知の不具合][link_known_issue] に原因と対策、改善の見通しをまとめたので再実行の前にご確認ください

[link_known_issue]: https://github.com/ToruMakabe/Understanding-K8s/blob/master/README.md#known_issue

## この章の対象ディレクトリ

```
.
├── chap12
│   ├── README.md (いまここ)
│   ├── cluster (AKSリソースHCLとヘルパースクリプト)
│   ├── modules (TerraformモジュールHCL)
│   └── shared (chap12共有リソースHCLとヘルパースクリプト)
└── shared
    └── env (環境変数設定スクリプト)
```

## 準備

作業ディレクトリの起点をchap12とします。

```
cd chap12
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

作業ディレクトリは引き続き chap12/shared です。

共有リソースを作成します。

```
./deploy.sh
```

## AKSクラスター作成

作業ディレクトリを chap12/cluster に変更し、クラスターを作成します。

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
* クラスター作成/削除中にPendingのPodが存在することで、アラートメールが送信されることがあります
  * もし作成/削除中のアラートを発生させたくない場合、以下の案があります
    * Alertリソース作成前に、Terraformのnullリソースを挟んで遅らせる
    * Alerリソースの作成を別のTerraformグループに分け、クラスター作成後、削除前の平常状態でapply/destroyを行う

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリはchap12/clusterを想定していますが、適宜読み替えてください。

```
./cleanup.sh
cd ../shared
./cleanup.sh
```