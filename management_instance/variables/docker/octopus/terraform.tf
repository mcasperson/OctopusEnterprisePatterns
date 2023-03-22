terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "DockerHub"
  description = "Variables related to interacting with DockerHub"

  template {
    name = "Tenant.Docker.Username"
    label = "The DockerHub Username"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Docker.Password"
    label = "The DockerHub Password"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }
}

