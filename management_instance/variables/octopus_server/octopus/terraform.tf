terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
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

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Octopus Server"
  description = "Variables related to interacting with an Octopus server"

  template {
    name = "Tenant.Octopus.Server"
    label = "The Octopus Server URL"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Octopus.ApiKey"
    label = "The Octopus Server API Key"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }

  template {
    name = "Tenant.Octopus.SpaceId"
    label = "The Octopus Server Space ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }
}

