terraform {
  backend "azurerm" {}
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config {
    storage_account_name = "${var.k8sbook_prefix}tfstate"
    container_name       = "tfstate-shared"
    key                  = "terraform.tfstate"
  }
}

data "terraform_remote_state" "cluster" {
  backend = "azurerm"

  config {
    storage_account_name = "${var.k8sbook_prefix}tfstate"
    container_name       = "tfstate-cls-blue"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {}

resource "azurerm_traffic_manager_endpoint" "todoapp-blue" {
  name                = "${var.k8sbook_prefix}-k8sbook-aio-todoapp-blue"
  resource_group_name = "${data.terraform_remote_state.shared.resource_group_name}"
  profile_name        = "${data.terraform_remote_state.shared.traffic_manager_profile_name}"
  target              = "${kubernetes_service.todoapp.load_balancer_ingress.0.ip}"
  type                = "externalEndpoints"
  priority            = 100
}

provider "kubernetes" {
  /*
  host                   = "${data.terraform_remote_state.cluster.host}"
  client_certificate     = "${data.terraform_remote_state.cluster.client_certificate}"
  client_key             = "${data.terraform_remote_state.cluster.client_key}"
  cluster_ca_certificate = "${data.terraform_remote_state.cluster.cluster_ca_certificate}"
*/
}

resource "kubernetes_service" "todoapp" {
  metadata {
    name = "todoapp"
  }

  spec {
    selector {
      app = "todoapp"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_secret" "cosmosdb" {
  metadata {
    name = "cosmosdb-secret"
  }

  data {
    MONGO_URL = "mongodb://${data.terraform_remote_state.shared.cosmosdb_account_name}:${data.terraform_remote_state.shared.cosmosdb_account_primary_master_key}@${data.terraform_remote_state.shared.cosmosdb_account_name}.documents.azure.com:10255/?ssl=true"
  }
}

data "azurerm_subscription" "current" {}

resource "kubernetes_secret" "cluster_autoscaler" {
  metadata {
    name      = "cluster-autoscaler-azure"
    namespace = "kube-system"
  }

  data {
    ClientID          = "${data.terraform_remote_state.cluster.sp_client_id}"
    ClientSecret      = "${data.terraform_remote_state.cluster.sp_client_secret}"
    ResourceGroup     = "${data.terraform_remote_state.shared.resource_group_name}"
    SubscriptionID    = "${substr(data.azurerm_subscription.current.id,15,-1)}"
    TenantID          = "${var.k8sbook_aad_tenant_id}"
    VMType            = "AKS"
    ClusterName       = "${data.terraform_remote_state.cluster.cluster_name}"
    NodeResourceGroup = "${data.terraform_remote_state.cluster.node_resource_group}"
  }
}

output "ClientID" {
  value = "${data.terraform_remote_state.cluster.sp_client_id}"
}

output "ClientSecret" {
  value = "${data.terraform_remote_state.cluster.sp_client_secret}"
}

output "ResourceGroup" {
  value = "${data.terraform_remote_state.shared.resource_group_name}"
}

output "TenantID" {
  value = "${var.k8sbook_aad_tenant_id}"
}

output "ClusterName" {
  value = "${data.terraform_remote_state.cluster.cluster_name}"
}

output "NodeResourceGroup" {
  value = "${data.terraform_remote_state.cluster.node_resource_group}"
}
