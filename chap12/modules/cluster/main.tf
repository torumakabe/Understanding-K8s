provider "azurerm" {
  version = "~>1.20.0"
}

data "azurerm_subscription" "current" {}

resource "azurerm_azuread_application" "aks" {
  name = "${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}"
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

resource "null_resource" "aadsync_delay" {
  // Wait for AAD async global replication
  provisioner "local-exec" {
    command = "sleep 90"
  }

  triggers = {
    "before" = "${azurerm_azuread_service_principal_password.aks.id}"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = ["null_resource.aadsync_delay"]

  name                = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"
  kubernetes_version  = "1.11.5"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"

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
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "${var.log_analytics_workspace_id}"
    }
  }
}

resource "azurerm_monitor_metric_alert" "pendning_pods" {
  name                = "pending_pods_${azurerm_kubernetes_cluster.aks.name}"
  resource_group_name = "${var.resource_group_name}"
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
    action_group_id = "${var.action_group_id_critical}"
  }
}
