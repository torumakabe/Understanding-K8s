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

## 実行の前に

* 以下のような理由でprep/deploy/cleanupスクリプト実行が途中終了した場合、環境変数を確認のうえ再実行してください
  * Terraform 既知の不具合
    * [認証トークンのリフレッシュに失敗することがある](https://github.com/terraform-providers/terraform-provider-azurerm/issues/2602)
      * [go-azure-helpersパッケージの修正で対応予定](https://github.com/hashicorp/go-azure-helpers/issues/22)
    * [Azure AD関連リソースの複製を待ちきれない](https://github.com/terraform-providers/terraform-provider-azuread/issues/4)
      * Azure ADの管理オブジェクトはデータセンター間で[非同期に複製](https://docs.microsoft.com/ja-jp/azure/active-directory/fundamentals/active-directory-architecture)されています
      * 参照はネットワーク的に近いAzure ADへ向かうため、リソース作成直後の問い合わせに複製が間に合わないことがあります
      * Terraformコミュニティで対処方針は議論中です
      * provisionerに回避ロジックを入れています
        * Terraformから問い合わせを受けるリソースは、Azure CLIでリソース作成完了を確認してから完了
        * Azureのリソースプロバイダーから問い合わせを受けるリソースは、30秒スリープしてから完了
    * [Cosmos DB削除時のリソース処理考慮漏れ](https://github.com/terraform-providers/terraform-provider-azurerm/pull/2702)
      * マルチリージョン構成などで、削除に時間がかかった場合に起こることがあります
      * Cosmos DBアカウントの削除はAzure側で進んでいるため、数分待つ or Azure CLIやポータルでCosmos DBが削除されたのを確認してから再実行してください
      * 修正はマージ済みで、Terraform AzureRM Provider v2.0.0でリリース予定
  * Terraform 実行の中断
    * 強制停止やキャンセル、ターミナルセッション断など
  * リソース作成に時間がかかりタイムアウト
    * Kubernetes Serviceに割り当てるパブリックIPなど
  * ヘルパースクリプト(prep/deploy/cleanup)は再実行できるように作っています

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

__このサンプルのTerraformとbashスクリプトは環境変数を使います。セッションを中断した/切れてしまった場合には、上記2つのスクリプトを再実行してください。冪等なので再実行可能です__

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
* クラスター作成/削除中にPendingのPodが存在することで、アラートメールが送信されることがあります
  * もし作成/削除中のアラートを発生させたくない場合、以下の案があります
    * Alertリソース作成前に、Terraformのnullリソースを挟んで遅らせる
    * Alerリソースの作成を別のTerraformグループに分け、クラスター作成後、削除前の平常状態でapply/destroyを行う

## リソースの削除

演習が終わったら、リソースを削除します。カレントディレクトリはch12/clusterを想定していますが、適宜読み替えてください。

```
./cleanup.sh
cd ../shared
./cleanup.sh
```