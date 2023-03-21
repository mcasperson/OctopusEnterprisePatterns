terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
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

data "octopusdeploy_projects" "provision_hello_world" {
  partial_name           = "Provision Hello World"
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_projects" "provision_azure_web_app" {
  partial_name           = "Provision Azure Web App"
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_projects" "initialise_space" {
  partial_name           = "Initialise Space"
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_environments" "production" {
  partial_name = "Production"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip = 0
  take = 1
}

data "octopusdeploy_library_variable_sets" "docker_hub" {
  partial_name = "DockerHub"
  skip = 0
  take = 1
}

data "octopusdeploy_library_variable_sets" "azure" {
  partial_name = "Azure"
  skip = 0
  take = 1
}

resource "octopusdeploy_tenant" "europe" {
  name        = "Europe"
  description = "The Europe DevOps team"
  tenant_tags = ["region/eu", "type/managed_instance"]

  project_environment {
    environments = [data.octopusdeploy_environments.production.environments[0].id]
    project_id   = data.octopusdeploy_projects.provision_hello_world.projects[0].id
  }

  project_environment {
    environments = [data.octopusdeploy_environments.production.environments[0].id]
    project_id   = data.octopusdeploy_projects.initialise_space.projects[0].id
  }

  project_environment {
    environments = [data.octopusdeploy_environments.production.environments[0].id]
    project_id   = data.octopusdeploy_projects.provision_azure_web_app.projects[0].id
  }
}

resource "octopusdeploy_tenant_common_variable" "octopus_server" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Octopus.Server"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.octopus_server
}

resource "octopusdeploy_tenant_common_variable" "octopus_server_api" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Octopus.ApiKey"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.octopus_apikey
}

resource "octopusdeploy_tenant_common_variable" "octopus_server_space_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Octopus.SpaceId"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = "Spaces-1628"
}

resource "octopusdeploy_tenant_common_variable" "docker_username" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Docker.Username"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.docker_username
}

resource "octopusdeploy_tenant_common_variable" "docker_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Docker.Password"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.docker_password
}

resource "octopusdeploy_tenant_common_variable" "azure_application_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Azure.ApplicationId"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.azure_application_id
}

resource "octopusdeploy_tenant_common_variable" "azure_subscription_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Azure.SubscriptionId"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.azure_subscription_id
}

resource "octopusdeploy_tenant_common_variable" "azure_tenant_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Azure.TenantId"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.azure_tenant_id
}

resource "octopusdeploy_tenant_common_variable" "azure_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template : tmp.id if tmp.name == "Tenant.Azure.Password"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = var.azure_password
}