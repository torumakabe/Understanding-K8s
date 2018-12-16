output "prefix" {
  value = "${var.k8sbook_prefix}"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.shared.name}"
}

output "resource_group_location" {
  value = "${azurerm_resource_group.shared.location}"
}
