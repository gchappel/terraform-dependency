variable storage_account_name {
  type        = string
}

variable resource_group_name {
  type        = string
}

variable "unique_id" {
  type = string
}

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "storage_account_name" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_redis_cache" "redis" {
  name     = "redis${var.unique_id}"
  location = data.azurerm_resource_group.resource_group.location
  tags     = {
    "Author" = "gchappell99"
  }

  resource_group_name = var.resource_group_name // this should probably come from an attribute from the data source, but it isn't in the problematic module so I'm not changing it here

  capacity            = 1
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"

  // TODO there is an entry in /var/lib/jenkins on jenkins-c7.3sp.co.uk to ignore the WARN in this section
  // https://github.com/terraform-providers/terraform-provider-azurerm/issues/6592
  redis_configuration {
    enable_authentication  = true
    maxmemory_policy       = "volatile-lru"
    notify_keyspace_events = ""
    rdb_backup_enabled     = true
    rdb_backup_frequency   = 15
    rdb_storage_connection_string = "DefaultEndpointsProtocol=https;BlobEndpoint=${data.azurerm_storage_account.storage_account_name.primary_blob_endpoint};AccountName=${data.azurerm_storage_account.storage_account_name.name};AccountKey=${data.azurerm_storage_account.storage_account_name.primary_access_key}"
    aof_backup_enabled            = false
  }

  # addresses https://github.com/Azure/azure-rest-api-specs/issues/3037
  # this primarily affects the idempotency of terratest tests, but may also affect any in-service changes
  lifecycle {
    ignore_changes = [
      redis_configuration.0.rdb_storage_connection_string,
    ]
  }
}
