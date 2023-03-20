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

variable "aws_access_key" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The AWS Access key."
}

variable "aws_secret_key" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The AWS Secret key."
}

resource "octopusdeploy_aws_account" "account_aws_account" {
  name                              = "AWS Account"
  description                       = ""
  environments                      = null
  tenant_tags                       = ["type/managed_instance"]
  tenants                           = null
  tenanted_deployment_participation = "TenantedOrUntenanted"
  access_key                        = var.aws_access_key
  secret_key                        = var.aws_secret_key
}