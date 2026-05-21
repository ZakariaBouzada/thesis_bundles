terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # RQ2 (Modularisation): State is stored locally for thesis development.
  # A production SME deployment would use a remote backend, e.g.:
  #   backend "azurerm" {
  #     resource_group_name  = "tfstate-rg"
  #     storage_account_name = "tfstateXXXXX"
  #     container_name       = "tfstate"
  #     key                  = "bundle-a.tfstate"
  #   }
  backend "local" {}
}

provider "azurerm" {
  features {
    key_vault {
      # Ensures Key Vault secrets are recoverable for 7 days after destroy.
      # Protects SMEs from accidental data loss.
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # Prevents accidental destruction of non-empty resource groups.
      prevent_deletion_if_contains_resources = true
    }
  }
}
