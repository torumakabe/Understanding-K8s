output "host" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"
}

output "client_certificate" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate}"
}

output "client_key" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config_raw}"
}

output "sp_client_id" {
  value = "${azurerm_azuread_application.aks.application_id}"
}

output "sp_client_secret" {
  value = "${azurerm_azuread_service_principal_password.aks.value}"
}

output "cluster_name" {
  value = "${azurerm_kubernetes_cluster.aks.name}"
}

output "node_resource_group" {
  value = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
}
