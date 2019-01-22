terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version = "~>1.21"
}

resource "azurerm_resource_group" "shared" {
  name     = "${var.k8sbook_prefix}-k8sbook-${var.k8sbook_chap}-rg"
  location = "${var.k8sbook_resource_group_location}"
}
