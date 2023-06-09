terraform {
  backend "s3" {
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
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

variable "existing_project_group" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the existing project group to place the project into."
  default     = ""
}

variable "project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the new project."
  default     = "Azure Web App (CaC)"
}

variable "cac_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The git url for the CaC project."
}

module "octopus" {
  source                 = "../octopus"
  existing_project_group = var.existing_project_group
  project_name           = var.project_name
  cac_url                = var.cac_url
  octopus_space_id       = var.octopus_space_id
}

output cac_url {
  value = module.octopus.cac_url
}

output project_name {
  value = module.octopus.project_name
}

output space_name {
  value = module.octopus.space_name
}