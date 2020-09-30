variable "resource_group_name" {
  type = string
}

variable "unique_id" {
  type = string
}

module "storage" {
  source = "./module_storage"
  resource_group_name = var.resource_group_name
  unique_id = var.unique_id
}

output "storage-id" {
  description = "Id of the storage account created."
  value       = module.storage.id
}

output "storage-name" {
  description = "Name of the storage account created."
  value       = module.storage.name
}

output "storage-primary-blob-host" {
  description = "The hostname with port if applicable for blob storage in the primary location."
  value       = module.storage.primary_blob_host
}