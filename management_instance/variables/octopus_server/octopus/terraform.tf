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

