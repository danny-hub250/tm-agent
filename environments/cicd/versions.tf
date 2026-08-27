terraform {

  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.63.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.9.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.1"
    }
  }

}
