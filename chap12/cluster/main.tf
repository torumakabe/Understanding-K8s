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

module "primary" {
  source = "../modules/cluster"

  prefix                     = "${var.k8sbook_prefix}"
  chap                       = "${var.k8sbook_chap}"
  cluster_type               = "primary"
  resource_group_name        = "${data.terraform_remote_state.shared.resource_group_name}"
  location                   = "${data.terraform_remote_state.shared.resource_group_location}"
  log_analytics_workspace_id = "${data.terraform_remote_state.shared.log_analytics_workspace_id}"
  action_group_id_critical   = "${data.terraform_remote_state.shared.action_group_id_critical}"
}
