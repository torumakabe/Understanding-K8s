terraform {
  backend "azurerm" {}
}

provider "azurerm" {}

resource "azurerm_resource_group" "shared" {
  name     = "${var.k8sbook_prefix}-k8sbook-aio-rg"
  location = "${var.k8sbook_resource_group_location}"
}

resource "azurerm_cosmosdb_account" "shared" {
  name                = "${var.k8sbook_prefix}-k8sbook-aio-db"
  location            = "${azurerm_resource_group.shared.location}"
  resource_group_name = "${azurerm_resource_group.shared.name}"
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = "${azurerm_resource_group.shared.location}"
    failover_priority = 0
  }

  geo_location {
    location          = "${var.k8sbook_failover_location}"
    failover_priority = 1
  }
}

resource "azurerm_traffic_manager_profile" "shared" {
  name                   = "${var.k8sbook_prefix}-k8sbook-aio-tm-todoapp"
  resource_group_name    = "${azurerm_resource_group.shared.name}"
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "${var.k8sbook_prefix}-k8sbook-aio-todoapp"
    ttl           = 60
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_role_assignment" "user01" {
  scope                = "${azurerm_resource_group.shared.id}"
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = "${var.k8sbook_aad_userid_1}"
}

resource "azurerm_log_analytics_workspace" "shared" {
  name                = "${var.k8sbook_prefix}-k8sbook-aio-workspace"
  location            = "${azurerm_resource_group.shared.location}"
  resource_group_name = "${azurerm_resource_group.shared.name}"
  sku                 = "Free"
}

resource "azurerm_monitor_action_group" "critical" {
  name                = "Critical"
  resource_group_name = "${azurerm_resource_group.shared.name}"
  short_name          = "Critical"

  email_receiver {
    name          = "Admin"
    email_address = "${var.k8sbook_admin_email_address}"
  }
}
