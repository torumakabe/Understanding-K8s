output "prefix" {
  value = "${var.k8sbook_prefix}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.shared.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.shared.location}"
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
