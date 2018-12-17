output "prefix" {
  value = "${var.k8sbook_prefix}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.shared.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.shared.location}"
}

output "log_analytics_workspace_id" {
  value = "${azurerm_log_analytics_workspace.shared.id}"
}

output "action_group_id_critical" {
  value = "${azurerm_monitor_action_group.critical.id}"
}
