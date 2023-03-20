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

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Azure"
  description = "Variables related to interacting with Azure"

  template {
    name = "Tenant.Azure.ApplicationId"
    label = "The Azure Application ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.SubscriptionId"
    label = "The Azure Subscription ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.TenantId"
    label = "The Azure Tenant ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.Password"
    label = "The Azure Password"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }
}
