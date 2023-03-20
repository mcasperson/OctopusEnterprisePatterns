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

data "octopusdeploy_projects" "provision_hello_world" {
  partial_name           = "Provision Hello World"
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_environments" "production" {
  partial_name = "Production"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_tenant" "europe" {
  name        = "Europe"
  description = "The Europe DevOps team"
  tenant_tags = ["region/eu"]

  project_environment {
    environments = [data.octopusdeploy_environments.production.environments[0].id]
    project_id   = data.octopusdeploy_projects.provision_hello_world.projects[0].id
  }
}
