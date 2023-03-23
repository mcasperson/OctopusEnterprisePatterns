terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
}

data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "docker" {
  feed_type    = "Docker"
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_deployment_process" "deployment_process_project" {
  project_id = "${octopusdeploy_project.project.id}"

  step {
    condition           = "Success"
    name                = "Get Logs"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AzurePowerShell"
      name                               = "Get Logs"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "OctopusUseBundledTooling" = "False"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
        "Octopus.Action.Azure.AccountId" = "${octopusdeploy_azure_service_principal.account_azure.id}"
        "Octopus.Action.Script.ScriptBody" = "# Loop because of https://github.com/Azure/azure-cli/issues/23563\n# Loop comes from http://jeromebelleman.gitlab.io/posts/devops/until/\ntimeout 1m bash -c 'until az webapp log download --name #{Octopus.Action.Azure.WebAppName} --resource-group #{Octopus.Action.Azure.ResourceGroupName} 2\u003e /dev/null; do sleep 2; done'\nnew_octopusartifact $${PWD}/webapp_logs.zip webapp_logs.zip\n"
      }

      container {
        feed_id = data.octopusdeploy_feeds.docker.feeds[0].id
        image   = "octopussamples/azure-cli"
      }

      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = ["octopub-webapp"]
  }
}

resource "octopusdeploy_project_group" "project_group" {
  name        = "Support"
  description = ""
}

resource "octopusdeploy_project" "project" {
  name                                 = "Get WebApp Logs"
  description                          = "An example of a project that is created by Terraform and owned by Terraform"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id}"
  project_group_id                     = "${octopusdeploy_project_group.project_group.id}"
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

data "octopusdeploy_worker_pools" "workerpool_hosted_ubuntu" {
  name = "Hosted Ubuntu"
  ids  = null
  skip = 0
  take = 1
}

data "octopusdeploy_lifecycles" "lifecycle_default_lifecycle" {
  ids          = null
  partial_name = "Default Lifecycle"
  skip         = 0
  take         = 1
}

