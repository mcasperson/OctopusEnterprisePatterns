terraform {
  backend "s3" {
  }
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

variable "docker_username" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "DockerHub username."
}

variable "docker_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "DockerHub password."
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

module "octopus" {
  source = "../octopus"
  octopus_server = var.octopus_server
  octopus_apikey = var.octopus_apikey
  octopus_space_id = var.octopus_space_id
  docker_username = var.docker_username
  docker_password = var.docker_password
  azure_application_id = var.azure_application_id
  azure_subscription_id = var.azure_subscription_id
  azure_password = var.azure_password
  azure_tenant_id = var.azure_tenant_id
}