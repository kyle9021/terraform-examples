provider "azuread" {
  version = "=0.7.0"
}

provider "random" {
  version = "=2.2.1"
}

provider "null" {
  version = "=2.1.2"
}

resource "azurerm_resource_group" "network" {
  name     = "${var.resource_name_prefix}-network-rgroup"
  location = var.location
  tags = {
    yor_trace = "9cb82d9f-6985-4214-8bb9-c5abe6aa19d1"
  }
}

resource "azurerm_virtual_network" "network" {
  name                = "${var.resource_name_prefix}-network"
  location            = var.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.137.0.0/16"]
  tags = {
    yor_trace = "64f70ac0-461d-402d-9237-1f873d3e88df"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_name_prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.network.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefix       = "10.137.1.0/24"
  service_endpoints    = ["Microsoft.KeyVault"]

  lifecycle {
    ignore_changes = [
      network_security_group_id,
      route_table_id
    ]
  }
}

resource "azurerm_resource_group" "storage" {
  name     = "${var.resource_name_prefix}-storage-rgroup"
  location = var.location
  tags = {
    yor_trace = "b1731a50-0cee-4910-acc8-c719cb163021"
  }
}

resource "azurerm_storage_account" "storage" {
  name                      = "${var.resource_name_prefix}storage"
  resource_group_name       = azurerm_resource_group.storage.name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  tags = {
    yor_trace = "29938bae-4c30-4330-a6a7-e3cd83ea5691"
  }
}

resource "azurerm_storage_container" "storage" {
  name                  = "${var.resource_name_prefix}container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "a_file" {
  name                   = "hello.txt"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.storage.name
  type                   = "Block"
  source_content         = "Hello, Blob!"
}
