terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version = "~>1.21"
}

resource "azurerm_resource_group" "shared" {
  name     = "${var.k8sbook_prefix}-k8sbook-${var.k8sbook_chap}-rg"
  location = "${var.k8sbook_resource_group_location}"
}

resource "azurerm_log_analytics_workspace" "shared" {
  name                = "${var.k8sbook_prefix}-k8sbook-${var.k8sbook_chap}-workspace"
  location            = "${azurerm_resource_group.shared.location}"
  resource_group_name = "${azurerm_resource_group.shared.name}"
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "shared" {
  solution_name         = "ContainerInsights"
  location              = "${azurerm_resource_group.shared.location}"
  resource_group_name   = "${azurerm_resource_group.shared.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.shared.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.shared.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_monitor_action_group" "critical" {
  name                = "critical"
  resource_group_name = "${azurerm_resource_group.shared.name}"
  short_name          = "critical"

  email_receiver {
    name          = "admin"
    email_address = "${var.k8sbook_admin_email_address}"
  }
}
