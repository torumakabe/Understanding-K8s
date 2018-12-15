terraform {
  backend "azurerm" {}
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config {
    storage_account_name = "${var.k8sbook_prefix}${var.k8sbook_chap}tfstate"
    container_name       = "tfstate-shared"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  version = "~>1.20.0"
}

data "azurerm_subscription" "current" {}

module "primary" {
  source = "../modules/cluster-green"

  prefix                              = "${var.k8sbook_prefix}"
  chap                                = "${var.k8sbook_chap}"
  cluster_type                        = "primary"
  subscription_id                     = "${data.azurerm_subscription.current.id}"
  resource_group_name                 = "${data.terraform_remote_state.shared.resource_group_name}"
  location                            = "${data.terraform_remote_state.shared.resource_group_location}"
  aad_tenant_id                       = "${var.k8sbook_aad_tenant_id}"
  log_analytics_workspace_id          = "${data.terraform_remote_state.shared.log_analytics_workspace_id}"
  action_group_id_critical            = "${data.terraform_remote_state.shared.action_group_id_critical}"
  traffic_manager_profile_name        = "${data.terraform_remote_state.shared.traffic_manager_profile_name}"
  traffic_manager_endpoint_priority   = 200
  cosmosdb_account_name               = "${data.terraform_remote_state.shared.cosmosdb_account_name}"
  cosmosdb_account_primary_master_key = "${data.terraform_remote_state.shared.cosmosdb_account_primary_master_key}"
}

module "failover" {
  source = "../modules/cluster-green"

  prefix                              = "${var.k8sbook_prefix}"
  chap                                = "${var.k8sbook_chap}"
  cluster_type                        = "failover"
  subscription_id                     = "${data.azurerm_subscription.current.id}"
  resource_group_name                 = "${data.terraform_remote_state.shared.resource_group_name}"
  location                            = "${var.k8sbook_failover_location}"
  aad_tenant_id                       = "${var.k8sbook_aad_tenant_id}"
  log_analytics_workspace_id          = "${data.terraform_remote_state.shared.log_analytics_workspace_id}"
  action_group_id_critical            = "${data.terraform_remote_state.shared.action_group_id_critical}"
  traffic_manager_profile_name        = "${data.terraform_remote_state.shared.traffic_manager_profile_name}"
  traffic_manager_endpoint_priority   = 600
  cosmosdb_account_name               = "${data.terraform_remote_state.shared.cosmosdb_account_name}"
  cosmosdb_account_primary_master_key = "${data.terraform_remote_state.shared.cosmosdb_account_primary_master_key}"
}
