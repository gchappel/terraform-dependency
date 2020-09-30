terraform {
  required_providers {
    azurerm = "~> 2.29"
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "unique_id" {
  type = string
}

module "core" {
  source = "./module_infra"
  resource_group_name = var.resource_group_name
  unique_id = var.unique_id
}

module "redis" {
  # depends_on = [
  #   module.core,
  # ]
  source = "./module_redis"
  resource_group_name = var.resource_group_name
  storage_account_name = module.core.storage-name
  unique_id = var.unique_id
}