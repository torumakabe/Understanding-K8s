output "prefix" {
  value = "${var.k8sbook_prefix}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.shared.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.shared.location}"
}

output "failover_location" {
  value = "${var.k8sbook_failover_location}"
}

output "cosmosdb_account_name" {
  value = "${azurerm_cosmosdb_account.shared.name}"
}

output "cosmosdb_account_primary_master_key" {
  value = "${azurerm_cosmosdb_account.shared.primary_master_key}"
}

output "traffic_manager_profile_name" {
  value = "${azurerm_traffic_manager_profile.shared.name}"
}

output "log_analytics_workspace_id" {
  value = "${azurerm_log_analytics_workspace.shared.id}"
}

output "action_group_id_critical" {
  value = "${azurerm_monitor_action_group.critical.id}"
}
