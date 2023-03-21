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

resource "octopusdeploy_environment" "environment_dev" {
  name                         = "Development"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 0

  jira_extension_settings {
    environment_type = "development"
  }

  jira_service_management_extension_settings {
    is_enabled = true
  }

  servicenow_extension_settings {
    is_enabled = true
  }
}

resource "octopusdeploy_environment" "environment_test" {
  name                         = "Test"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 1

  jira_extension_settings {
    environment_type = "unmapped"
  }

  jira_service_management_extension_settings {
    is_enabled = false
  }

  servicenow_extension_settings {
    is_enabled = false
  }
}

resource "octopusdeploy_environment" "environment_production" {
  name                         = "Production"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 2

  jira_extension_settings {
    environment_type = "unmapped"
  }

  jira_service_management_extension_settings {
    is_enabled = false
  }

  servicenow_extension_settings {
    is_enabled = false
  }
}

resource "octopusdeploy_environment" "environment_security" {
  name                         = "Security"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 3

  jira_extension_settings {
    environment_type = "unmapped"
  }

  jira_service_management_extension_settings {
    is_enabled = false
  }

  servicenow_extension_settings {
    is_enabled = false
  }
}

resource "octopusdeploy_lifecycle" "devsecops_lifecycle" {
  description = "Lifecycle including security scanning"
  name        = "DevSecOps"

  release_retention_policy {
    quantity_to_keep    = 1
    should_keep_forever = true
    unit                = "Days"
  }

  tentacle_retention_policy {
    quantity_to_keep    = 30
    should_keep_forever = false
    unit                = "Items"
  }

  phase {
    automatic_deployment_targets = []
    optional_deployment_targets  = [octopusdeploy_environment.environment_dev.id]
    name                         = octopusdeploy_environment.environment_dev.name

    release_retention_policy {
      quantity_to_keep    = 1
      should_keep_forever = true
      unit                = "Days"
    }

    tentacle_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = false
      unit                = "Items"
    }
  }

  phase {
    automatic_deployment_targets = []
    optional_deployment_targets  = [octopusdeploy_environment.environment_test.id]
    name                         = octopusdeploy_environment.environment_test.name

    release_retention_policy {
      quantity_to_keep    = 1
      should_keep_forever = true
      unit                = "Days"
    }

    tentacle_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = false
      unit                = "Items"
    }
  }

  phase {
    automatic_deployment_targets = []
    optional_deployment_targets  = [octopusdeploy_environment.environment_production.id]
    name                         = octopusdeploy_environment.environment_production.name

    release_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = true
      unit                = "Days"
    }

    tentacle_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = false
      unit                = "Items"
    }
  }

  phase {
    automatic_deployment_targets = [octopusdeploy_environment.environment_security.id]
    optional_deployment_targets  = []
    name                         = octopusdeploy_environment.environment_security.name

    release_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = true
      unit                = "Days"
    }

    tentacle_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = false
      unit                = "Items"
    }
  }
}