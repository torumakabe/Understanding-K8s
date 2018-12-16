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
  scope                = "${var.subscription_id}"
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
  name                = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"
  kubernetes_version  = "1.11.5"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"

  agent_pool_profile {
    name            = "default"
    count           = 1
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
  }
}

provider "kubernetes" {
  load_config_file       = false
  host                   = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
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
    ResourceGroup     = "${var.resource_group_name}"
    SubscriptionID    = "${substr(var.subscription_id,15,-1)}"
    TenantID          = "${var.aad_tenant_id}"
    VMType            = "AKS"
    ClusterName       = "${azurerm_kubernetes_cluster.aks.name}"
    NodeResourceGroup = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  }
}
