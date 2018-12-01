terraform {
  backend "azurerm" {}
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"

  config {
    storage_account_name = "${var.k8sbook_prefix}aiotfstate"
    container_name       = "tfstate-shared"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {}

data "azurerm_subscription" "current" {}

resource "azurerm_azuread_application" "aks" {
  name = "${data.terraform_remote_state.shared.prefix}-k8sbook-sp-aks-blue"
}

resource "azurerm_azuread_service_principal" "aks" {
  application_id = "${azurerm_azuread_application.aks.application_id}"
}

resource "azurerm_role_assignment" "aks" {
  scope                = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azurerm_azuread_service_principal.aks.id}"
}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azurerm_azuread_service_principal_password" "aks" {
  end_date             = "2299-12-30T23:00:00Z"                        # Forever
  service_principal_id = "${azurerm_azuread_service_principal.aks.id}"
  value                = "${random_string.password.result}"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${data.terraform_remote_state.shared.prefix}-k8sbook-aio-aks-blue"
  kubernetes_version  = "1.11.4"
  location            = "${data.terraform_remote_state.shared.resource_group_location}"
  resource_group_name = "${data.terraform_remote_state.shared.resource_group_name}"
  dns_prefix          = "${data.terraform_remote_state.shared.prefix}-k8sbook-aio-aks-blue"

  agent_pool_profile {
    name            = "default"
    count           = 2
    vm_size         = "Standard_D2s_v3"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${azurerm_azuread_application.aks.application_id}"
    client_secret = "${azurerm_azuread_service_principal_password.aks.value}"
  }

  role_based_access_control {
    azure_active_directory {
      client_app_id     = "${var.k8sbook_aad_client_app_id}"
      server_app_id     = "${var.k8sbook_aad_server_app_id}"
      server_app_secret = "${var.k8sbook_aad_server_app_secret}"
    }
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "${data.terraform_remote_state.shared.log_analytics_workspace_id}"
    }
  }
}

resource "azurerm_monitor_metric_alert" "pendning_pods" {
  name                = "pending_pods"
  resource_group_name = "${data.terraform_remote_state.shared.resource_group_name}"
  scopes              = ["${azurerm_kubernetes_cluster.aks.id}"]
  description         = "Action will be triggered when pending pods count is greater than 0."

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_phase"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      "name"     = "phase"
      "operator" = "Include"
      "values"   = ["Pending"]
    }
  }

  action {
    action_group_id = "${data.terraform_remote_state.shared.action_group_id_critical}"
  }
}
