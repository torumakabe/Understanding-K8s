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

  provisioner "local-exec" {
    command = "az aks get-credentials -g ${data.terraform_remote_state.shared.resource_group_name} -n ${data.terraform_remote_state.shared.prefix}-k8sbook-aio-aks-blue --overwrite-existing --admin"
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

provider "kubernetes" {
  /*
  host                   = "${data.terraform_remote_state.cluster.host}"
  client_certificate     = "${data.terraform_remote_state.cluster.client_certificate}"
  client_key             = "${data.terraform_remote_state.cluster.client_key}"
  cluster_ca_certificate = "${data.terraform_remote_state.cluster.cluster_ca_certificate}"
*/
}

resource "kubernetes_service" "todoapp" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  metadata {
    name = "todoapp"
  }

  spec {
    selector {
      app = "todoapp"
    }

    session_affinity = "ClientIP"

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "azurerm_traffic_manager_endpoint" "todoapp-blue" {
  name                = "${var.k8sbook_prefix}-k8sbook-aio-todoapp-blue"
  resource_group_name = "${data.terraform_remote_state.shared.resource_group_name}"
  profile_name        = "${data.terraform_remote_state.shared.traffic_manager_profile_name}"
  target              = "${kubernetes_service.todoapp.load_balancer_ingress.0.ip}"
  type                = "externalEndpoints"
  priority            = 100
}

resource "kubernetes_secret" "cosmosdb" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  metadata {
    name = "cosmosdb-secret"
  }

  data {
    MONGO_URL = "mongodb://${data.terraform_remote_state.shared.cosmosdb_account_name}:${data.terraform_remote_state.shared.cosmosdb_account_primary_master_key}@${data.terraform_remote_state.shared.cosmosdb_account_name}.documents.azure.com:10255/?ssl=true"
  }
}

resource "kubernetes_secret" "cluster_autoscaler" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  metadata {
    name      = "cluster-autoscaler-azure"
    namespace = "kube-system"
  }

  data {
    ClientID          = "${azurerm_azuread_application.aks.application_id}"
    ClientSecret      = "${azurerm_azuread_service_principal_password.aks.value}"
    ResourceGroup     = "${data.terraform_remote_state.shared.resource_group_name}"
    SubscriptionID    = "${substr(data.azurerm_subscription.current.id,15,-1)}"
    TenantID          = "${var.k8sbook_aad_tenant_id}"
    VMType            = "AKS"
    ClusterName       = "${azurerm_kubernetes_cluster.aks.name}"
    NodeResourceGroup = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  }
}
