# [翔泳社 しくみがわかる Kubernetes](https://www.shoeisha.co.jp/book/detail/9784798157849) サンプルコード

![colver](https://www.seshop.com/static/images/product/22378/L.png)

Gitがインストールされた環境で、以下のコマンドを実行し、クローンして利用してください。

```bash
$ git clone https://github.com/ToruMakabe/Understanding-K8s
```

ここでは、サンプルコードの概要について説明します。

---

## 第1部 導入編

### chap01

第1章、コンテナーとKubernetesの概要について説明しています。

※ ここでは、サンプルコードを利用しません。

### chap02

第2章、Kubernetesの環境構築を行う章です。ここでは簡単なPython-FlaskアプリケーションのDockerイメージを作成し、レジストリにビルドします。
また、3台のワーカーノードからなる構成のクラスタを作成します。

### chap03

第3章、Kubernetesのチュートリアルを行います。ここでは、サンプルアプリのDockerイメージをKubernetesのクラスタで実行し、動作確認と開発の流れを確認します。

## 第2部 基本編

### chap04

第4章、Kubernetesの要点を確認するためのサンプルです。KubernetesのLabelsやマニュフェストの書き方、namespaceによるリソース分離などを確認します。

### chap05

第5章、コンテナーアプリケーションの実行を確認するためのサンプルです。Pod／ReplicaSetの基本的な動作に加え、 livenessProbe ／ReadinessProbeによるヘルスチェック、水平Podオートスケーラーなどのしくみを確認します。

### chap06

第6章、Deploymentによるアプリケーションのデプロイを確認するためのサンプルです。バージョンの異なるサンプルアプリケーションイメージを使用してRollingUpdateします。またアプリケーションイメージから設定情報／秘匿情報を分離するためのConfigMapやSecretsの確認も行います。

---  

## 第3部 実践編

### サンプルの設計方針

![AIO](https://github.com/ToruMakabe/Understanding-K8s/blob/master/pics/ch-aio.jpg?raw=true "AIO")

* Terraformを主に使います
  * Azure関連リソースとKubernetes関連リソースをまとめて作成できることを重視しました
* Terraformでの管理単位を、共用リソース(shared)、AKSクラスター(cluster-xxx)で分割しています
  * ライフサイクルとリスクプロファイルが異なるためです
  * さらに該当する章ではBlue/Greenクラスターで分割しています
  * deploy/cleanup用 ヘルパーbashスクリプトからTerraformを実行します
* シークレットは主に環境変数で渡しています
  * よりセキュアにするにはAzure Key Vaultもご検討ください
* サンプルToDoアプリのコンテナーイメージはDocker Hubで公開しています
  * ソースは[shared/app/todo](https://github.com/ToruMakabe/Understanding-K8s/tree/master/shared/app/todo)にあります
* 実行方法は各章のREADMEをご覧ください
* 以下環境でテストしています
  * Windows Subsystem for Linux (Ubuntu 18.04)
  * macOS Mojave 10.14.2
  * Azure CLI 2.0.52
  * Terraform 0.11.10

### chap08-12-all-in-one

第3部で説明した環境を全部入りで作成できます。各章で都度環境を作成、削除したくない時はこちらを。
クラスターが4つ作成されますので、コストやリソース制限にご注意を。

### chap08

第8章、可用性に関する設計、機能を試すコードです。Primary/Failover 2つのクラスターで冗長化します。

* Primary/Failover 2つのAKSクラスター
* PrimaryとFailoverはリージョンを分けて作成可能
* 共有リソースとしてAzure Cosmos DBとAzure Traffic Manager
* サンプルToDoアプリ

### chap09

第9章、拡張性に関する設計、機能を試すコードです。Cluster Autoscalerを導入します。

* 1つのAKSクラスター
* Cluster Autoscaler
* NGINX Deploymentマニフェスト (Pending状態のPod作成用)

### chap10

第10章、保守性に関する設計、機能を試すコードです。Blue/Green 2つのクラスターで冗長化します。

* Blue/Green 2つのAKSクラスター
* 共有リソースとしてAzure Cosmos DBとAzure Traffic Manager
* サンプルToDoアプリケーション
* Kured関連マニフェスト
* NGINX Deploymentマニフェスト (Cordon/Drainの挙動確認用)

### chap11

第11章、リソース分離に関する設計、機能を試すコードです。Azure AD(Active Directory)との認証統合を設定します。Azure AD認証なしの演習オプションも用意しました。

* 1つのAKSクラスター
* Azure Active Directory統合設定
* リソース分離関連マニフェスト (Namespace、Role、Role Bindingなど)
* 負荷がけ用アプリ

### chap12

第12章、可観測性に関する設計、機能を試すコードです。Azure Monitor関連の設定をします。

* 1つのAKSクラスター
* Azure Monitor関連設定

### <a name ="known_issue">既知の不具合</a>

__以下が原因でエラーとなった場合、直前に実行したヘルパースクリプト(prep/deploy/cleanup)を再実行してください__

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
    * 修正はマージ済みで、Terraform AzureRM Provider v1.22.0でリリース予定
* Terraformのタイムアウト値が短め、かつ固定値にて変更できないリソース
  * Kubernetes Service リソースなど (Load BalancerへのパブリックIP割り当てを待てない)
