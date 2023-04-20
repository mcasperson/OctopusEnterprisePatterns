terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Config As Code"
  description = "Variables related to interacting with an Octopus server"

  template {
    name = "Tenant.CaC.Url"
    label = "The Git URL"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

    template {
      name = "Tenant.CaC.Org"
      label = "The Git organization"
      display_settings = {
        "Octopus.ControlType": "SingleLineText"
      }
    }

  template {
    name = "Tenant.CaC.Password"
    label = "The Git Password"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }

  template {
    name = "Tenant.CaC.Username"
    label = "The Git Username"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }
}

