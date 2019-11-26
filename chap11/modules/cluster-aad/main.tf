provider "azurerm" {
  version = "~>1.21"
}

provider "azuread" {
  version = "~>0.1"
}

provider "random" {
  version = "~>2.0"
}

data "azurerm_subscription" "current" {}

resource "azuread_application" "aks" {
  name            = "${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}"
  identifier_uris = ["https://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}"]

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        OID=$(az ad app show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}" -o tsv --query objectId)
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
        SP_OID=$(az ad sp show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}" -o tsv --query objectId)
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

resource "random_string" "password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "aks" {
  end_date             = "2299-12-30T23:00:00Z" # Forever
  service_principal_id = "${azuread_service_principal.aks.id}"
  value                = "${random_string.password.result}"

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        SP_OID=$(az ad sp show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-${var.cluster_type}" -o tsv --query objectId)
        if [ -n "$SP_OID" ]; then
            echo "Completed Azure AD Replication (SP Password)"
            break
        else
            echo "Waiting for Azure AD Replication (SP Password)..."
            sleep 5
        fi
    done
    EOT
  }
}

resource "azurerm_role_assignment" "aks" {
  depends_on           = ["azuread_service_principal_password.aks"]
  scope                = "${data.azurerm_subscription.current.id}"
  role_definition_name = "Contributor"
  principal_id         = "${azuread_service_principal.aks.id}"

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  // For AAD global replication
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on          = ["azurerm_role_assignment.aks"]
  name                = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"
  kubernetes_version  = "1.11.9"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.prefix}-k8sbook-${var.chap}-aks-${var.cluster_type}"

  agent_pool_profile {
    name    = "default"
    count   = 2
    vm_size = "Standard_D2s_v3"
    os_type = "Linux"
  }

  service_principal {
    client_id     = "${azuread_application.aks.application_id}"
    client_secret = "${random_string.password.result}"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      tenant_id         = "${var.aad_ext_tenant_id == "" ? var.aad_tenant_id : var.aad_ext_tenant_id}"
      client_app_id     = "${var.aad_client_app_id}"
      server_app_id     = "${var.aad_server_app_id}"
      server_app_secret = "${var.aad_server_app_secret}"
    }
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
}
