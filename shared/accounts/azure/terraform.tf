terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.0" }
  }
}

terraform {
  backend "s3" {
  }
}

provider "octopusdeploy" {
  address  = "${var.octopus_server}"
  api_key  = "${var.octopus_apikey}"
  space_id = "${var.octopus_space_id}"
}

variable "octopus_server" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The URL of the Octopus server e.g. https://myinstance.octopus.app."
}

variable "octopus_apikey" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The API key used to access the Octopus server. See https://octopus.com/docs/octopus-rest-api/how-to-create-an-api-key for details on creating an API key."
}

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."
}

variable "azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
}

variable "azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
}

variable "azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
}

variable "azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
}

resource "octopusdeploy_azure_service_principal" "account_azure" {
  description                       = "Azure Account"
  name                              = "Azure"
  environments                      = null
  tenant_tags                       = []
  tenants                           = null
  tenanted_deployment_participation = "TenantedOrUntenanted"
  application_id                    = var.azure_application_id
  password                          = var.azure_password
  subscription_id                   = var.azure_subscription_id
  tenant_id                         = var.azure_tenant_id
}