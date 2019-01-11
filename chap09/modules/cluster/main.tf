provider "azurerm" {
  version = "~>1.20.0"
}

provider "azuread" {}

data "azurerm_subscription" "current" {}

resource "azuread_application" "aks" {
  name            = "${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}"
  identifier_uris = ["http://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}"]

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        OID=$(az ad app show --id "http://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}" -o tsv --query objectId)
        if [ -n "$OID" ]; then
            echo "Completed Azure AD Replication (App)"
            break
        else
            echo "Waiting for Azure AD Replication (App)..."
            sleep 5
        fi
    done
    EOT
  }
}

resource "azuread_service_principal" "aks" {
  application_id = "${azuread_application.aks.application_id}"

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        SP_OID=$(az ad sp show --id "http://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}" -o tsv --query objectId)
        if [ -n "$SP_OID" ]; then
            echo "Completed Azure AD Replication (SP)"
            break
        else
            echo "Waiting for Azure AD Replication (SP)..."
            sleep 5
        fi
    done
    EOT
  }
}

resource "azurerm_role_assignment" "aks" {
  scope                = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azuread_service_principal.aks.id}"
}

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks" {
  depends_on           = ["azurerm_role_assignment.aks"]
  end_date             = "2299-12-30T23:00:00Z"                # Forever
  service_principal_id = "${azuread_service_principal.aks.id}"
  value                = "${random_string.password.result}"
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on          = ["azurerm_role_assignment.aks"]
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
    client_id     = "${azuread_application.aks.application_id}"
    client_secret = "${random_string.password.result}"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }

  lifecycle {
    // For Cluster Autoscaler
    ignore_changes = ["agent_pool_profile.0.count"]
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
    ClientID          = "${azuread_application.aks.application_id}"
    ClientSecret      = "${azuread_service_principal_password.aks.value}"
    ResourceGroup     = "${var.resource_group_name}"
    SubscriptionID    = "${substr(data.azurerm_subscription.current.id,15,-1)}"
    TenantID          = "${var.aad_tenant_id}"
    VMType            = "AKS"
    ClusterName       = "${azurerm_kubernetes_cluster.aks.name}"
    NodeResourceGroup = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  }
}
