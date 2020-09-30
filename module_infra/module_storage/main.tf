variable "resource_group_name" {
  type        = string
}

variable "unique_id" {
  type = string
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "storage" {
  name                      = "strg${var.unique_id}"
  resource_group_name       = var.resource_group_name // this should probably come from an attribute from the data source, but it isn't in the problematic module so I'm not changing it here
  location                  = data.azurerm_resource_group.resource_group.location
  account_tier              = "Standard"
  account_replication_type  = "ZRS"
  account_kind              = "StorageV2"
  tags                      = {
    "Author" = "gchappell99"
  }
  is_hns_enabled            = false
  enable_https_traffic_only = true

  identity {
    type = "SystemAssigned"
  }

  queue_properties {
    // This section is requred else terrafrom crashes
    logging {
      delete                = false
      read                  = false
      write                 = false
      version               = "1.0"
      retention_policy_days = 1
    }

    hour_metrics {
      enabled               = true
      include_apis          = true
      version               = "1.0"
      retention_policy_days = 7
    }

    minute_metrics {
      enabled               = false
      include_apis          = false
      version               = "1.0"
      retention_policy_days = 1
    }
  }
}

resource "azurerm_storage_container" "storage" {
  for_each              = {"test" = "private"}
  name                  = each.key
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = each.value
}

output "id" {
  description = "Id of the storage account created."
  value       = azurerm_storage_account.storage.id
}

output "name" {
  description = "Name of the storage account created."
  value       = azurerm_storage_account.storage.name
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location."
  value       = azurerm_storage_account.storage.primary_blob_host
}