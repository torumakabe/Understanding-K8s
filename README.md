# [翔泳社 しくみがわかる Kubernetes](https://www.shoeisha.co.jp/book/detail/9784798157849) サンプルコード [工事中]

## 第1部 導入編

## 第2部 基本編

## 第3部 実践編

### サンプルの設計方針

* Azure関連リソースとKubernetes関連リソースをまとめて作成できる、Terraformを主に使います
* TerraformのModuleはコードの再利用に有用ですが、Azure、Kubernetes、Terraformそれぞれ進化が早いソフトウェアであるため、新/旧、Blue/Greenクラスターでコードを分けたいことも多いです。よってこのサンプルではModuleを使っていません
* Terraformでの管理単位を、共用リソース、AKSクラスター、クラスター上のリソースで分割しています。ライフサイクルとリスクプロファイルが異なるためです
* シークレットは主に環境変数で渡していますが、よりセキュアにするにはAzure Key Vaultもおすすめです

### chap08-12-all-in-one

第3部で説明した環境を全部入りで作成できます。各章で都度環境を作成、削除したくない時はこちらを。

### chap08

第8章、可用性に関する設計、機能を試すコードです。Blue/Green 2つのクラスターで冗長化します。

* Blue/Green 2つのAKSクラスター
* 共有リソースとしてAzure Cosmos DBとAzure Traffic Manager
* サンプルToDoアプリ

### chap09

第9章、拡張性に関する設計、機能を試すコードです。Cluster Autoscalerを導入します。

* 1つのAKSクラスター
* Cluster Autoscaler
* NGINX Deploymentマニフェスト (Pending状態のPod作成用)

### chap10

第10章、保守性に関する設計、機能を試すコードです。Blue/Green 2つのクラスターで冗長化します。クラスターの作りは8章と同じです。

* Blue/Green 2つのAKSクラスター
* 共有リソースとしてAzure Cosmos DBとAzure Traffic Manager
* サンプルToDoアプリケーション
* Kured関連マニフェスト
* NGINX Deploymentマニフェスト (Cordon/Drainの挙動確認用)

### chap11

第11章、リソース分離に関する設計、機能を試すコードです。Azure Active Directoryとの認証統合を設定します。

* 1つのAKSクラスター
* Azure Active Directory統合設定
* リソース分離関連マニフェスト (Namespace、Role、Role Bindingなど)
* 負荷がけ用アプリ

### chap12

第12章、可観測性に関する設計、機能を試すコードです。Azure Monitor関連の設定をします。

* 1つのAKSクラスター
* Azure Monitor関連設定