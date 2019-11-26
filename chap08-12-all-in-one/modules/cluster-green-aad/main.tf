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
  name            = "${var.prefix}-k8sbook-${var.chap}-sp-aks-green-${var.cluster_type}"
  identifier_uris = ["https://${var.prefix}-k8sbook-${var.chap}-sp-aks-green-${var.cluster_type}"]

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        OID=$(az ad app show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-green-${var.cluster_type}" -o tsv --query objectId)
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
        SP_OID=$(az ad sp show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-green-${var.cluster_type}" -o tsv --query objectId)
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
  end_date             = "2299-12-30T23:00:00Z"                # Forever
  service_principal_id = "${azuread_service_principal.aks.id}"
  value                = "${random_string.password.result}"

  // Working around the following issue https://github.com/terraform-providers/terraform-provider-azurerm/issues/1635
  provisioner "local-exec" {
    command = <<EOT
    while :
    do
        SP_OID=$(az ad sp show --id "https://${var.prefix}-k8sbook-${var.chap}-sp-aks-green-${var.cluster_type}" -o tsv --query objectId)
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
  name                = "${var.prefix}-k8sbook-${var.chap}-aks-green-${var.cluster_type}"
  kubernetes_version  = "1.11.9"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  dns_prefix          = "${var.prefix}-k8sbook-${var.chap}-aks-green-${var.cluster_type}"

  agent_pool_profile {
    name            = "default"
    count           = 2
    vm_size         = "Standard_D2s_v3"
    os_type         = "Linux"
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

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "${var.log_analytics_workspace_id}"
    }
  }

  lifecycle {
    // For Cluster Autoscaler
    ignore_changes = ["agent_pool_profile.0.count"]
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

provider "kubernetes" {
  version                = "~>1.5"
  load_config_file       = false
  host                   = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
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

resource "azurerm_traffic_manager_endpoint" "todoapp-green" {
  name                = "${var.prefix}-k8sbook-${var.chap}-todoapp-green-${var.cluster_type}"
  resource_group_name = "${var.resource_group_name}"
  profile_name        = "${var.traffic_manager_profile_name}"
  target              = "${kubernetes_service.todoapp.load_balancer_ingress.0.ip}"
  type                = "externalEndpoints"
  priority            = "${var.traffic_manager_endpoint_priority}"
}

resource "kubernetes_secret" "cosmosdb" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  metadata {
    name = "cosmosdb-secret"
  }

  data {
    MONGO_URL = "mongodb://${var.cosmosdb_account_name}:${var.cosmosdb_account_primary_master_key}@${var.cosmosdb_account_name}.documents.azure.com:10255/?ssl=true"
  }
}

resource "kubernetes_deployment" "todoapp" {
  metadata {
    name = "todoapp"
  }

  spec {
    replicas = 2

    selector {
      match_labels {
        app = "todoapp"
      }
    }

    template {
      metadata {
        labels {
          app = "todoapp"
        }
      }

      spec {
        container {
          image = "torumakabe/todo-app:0.0.2"
          name  = "todoapp"

          port {
            container_port = 8080
          }

          env {
            name = "MONGO_URL"

            value_from {
              secret_key_ref {
                name = "cosmosdb-secret"
                key  = "MONGO_URL"
              }
            }
          }

          resources {
            limits {
              cpu    = "250m"
              memory = "100Mi"
            }

            requests {
              cpu    = "250m"
              memory = "100Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_secret" "cluster_autoscaler" {
  depends_on = ["azurerm_kubernetes_cluster.aks"]

  metadata {
    name      = "cluster-autoscaler-azure"
    namespace = "kube-system"
  }

  data {
    ClientID          = "${azuread_application.aks.application_id}"
    ClientSecret      = "${random_string.password.result}"
    ResourceGroup     = "${var.resource_group_name}"
    SubscriptionID    = "${substr(data.azurerm_subscription.current.id,15,-1)}"
    TenantID          = "${var.aad_tenant_id}"
    VMType            = "AKS"
    ClusterName       = "${azurerm_kubernetes_cluster.aks.name}"
    NodeResourceGroup = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  }
}
