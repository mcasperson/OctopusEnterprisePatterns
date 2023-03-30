terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
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

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."
}

data "octopusdeploy_lifecycles" "lifecycle_default_lifecycle" {
  ids          = null
  partial_name = "Default Lifecycle"
  skip         = 0
  take         = 1
}

data "octopusdeploy_lifecycles" "lifecycle_devsecops" {
  ids          = null
  partial_name = "DevSecOps"
  skip         = 0
  take         = 1
}

data "octopusdeploy_git_credentials" "gitcredential" {
  name = "GitHub"
  skip = 0
  take = 1
}

data "octopusdeploy_project_groups" "project_group" {
  partial_name = var.existing_project_group
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project_group" "project_group" {
  count = var.existing_project_group == "" ? 1 : 0
  name  = "Azure Web App (CaC)"
}

resource "octopusdeploy_project" "project" {
  lifecycle {
    ignore_changes = [
      connectivity_policy,
    ]
  }

  name                                 = var.project_name
  description                          = <<EOT
This project is based on the CaC code from a template repo. To merge updates from the source template, run the following commands:
* `git clone ${var.cac_url}`
* `cd ${trimsuffix(element(split("/", var.cac_url), length(split("/", var.cac_url)) - 1), ".git")}`
* `git remote add upstream https://github.com/mcasperson/OctopusEnterprisePatternsAzureWebAppCaCTemplate.git`
* `git fetch --all`
* `git checkout -b upstream-octopus-vcs-conversion upstream/octopus-vcs-conversion`
* `git checkout -b octopus-vcs-conversion origin/octopus-vcs-conversion`
* `git merge upstream-octopus-vcs-conversion`
    EOT
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = true
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_devsecops.lifecycles[0].id}"
  project_group_id                     = var.existing_project_group == "" ? octopusdeploy_project_group.project_group[0].id : data.octopusdeploy_project_groups.project_group.project_groups[0].id
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }

  git_library_persistence_settings {
    git_credential_id  = data.octopusdeploy_git_credentials.gitcredential.git_credentials[0].id
    url                = var.cac_url
    base_path          = ".octopus/azure-web-app"
    default_branch     = "octopus-vcs-conversion"
    protected_branches = []
  }
}