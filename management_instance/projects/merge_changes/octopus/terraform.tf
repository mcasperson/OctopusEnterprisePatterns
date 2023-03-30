terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
}

data "octopusdeploy_channels" "channel_default" {
  ids          = null
  partial_name = "Default"
  skip         = 0
  take         = 1
}

data "octopusdeploy_lifecycles" "lifecycle" {
  ids          = null
  partial_name = "Managed Instance"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "built_in_feed" {
  feed_type    = "BuiltIn"
  ids          = null
  partial_name = ""
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "config_as_code" {
  partial_name = "Config As Code"
  skip = 0
  take = 1
}

data "octopusdeploy_feeds" "docker" {
  feed_type    = "Docker"
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

data "octopusdeploy_worker_pools" "workerpool_hosted_ubuntu" {
  name = "Hosted Ubuntu"
  ids  = null
  skip = 0
  take = 1
}

data "octopusdeploy_project_groups" "project_group" {
  partial_name = "Azure Web App"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project" "project" {
  name                                 = "Azure Web App (Merge Changes)"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = ""
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle.lifecycles[0].id}"
  project_group_id                     = data.octopusdeploy_project_groups.project_group.project_groups[0].id
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.config_as_code.library_variable_sets[0].id
  ]
  tenanted_deployment_participation    = "Tenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_variable" "project_name_variable" {
  owner_id  = octopusdeploy_project.project.id
  type      = "String"
  name      = "Project.Name"
  value     = "Azure Web App (CaC)"
  prompt {
    description = "The name of the new project"
    is_required = true
    label       = "Project Name"
  }
}

resource "octopusdeploy_deployment_process" "deployment_process" {
  project_id = "${octopusdeploy_project.project.id}"

  step {
    condition           = "Success"
    name                = "Merge Deployment Process"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Merge Deployment Process"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
         "Octopus.Action.Script.ScriptBody" = "NEW_REPO=\"#{Octopus.Deployment.Tenant.Name | ToLower}-#{Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}\"\nTEMPLATE_REPO=https://github.com/mcasperson/OctopusEnterprisePatternsAzureWebAppCaCTemplate.git\nBRANCH=octopus-vcs-conversion\n\ncd gh/gh_2.25.1_linux_amd64/bin\n\n# Fix executable flag\nchmod +x gh\n\n# Log into GitHub\ncat \u003c\u003c\u003c #{Tenant.CaC.Password} | ./gh auth login --with-token\n\n# Use the github cli as the credential helper\n./gh auth setup-git\n\n# Replace these with some sensible values\ngit config --global user.email \"octopus@octopus.com\" 2\u003e\u00261\ngit config --global user.name \"Octopus Server\" 2\u003e\u00261\n\ngit clone #{Tenant.CaC.Url}$${NEW_REPO}.git 2\u003e\u00261\ncd $${NEW_REPO}\ngit remote add upstream $TEMPLATE_REPO 2\u003e\u00261\ngit fetch --all 2\u003e\u00261\ngit checkout -b upstream-$BRANCH upstream/$BRANCH 2\u003e\u00261\ngit checkout -b $BRANCH origin/$BRANCH 2\u003e\u00261\ngit merge --no-commit upstream-$BRANCH 2\u003e\u00261\n\nif [[ $? == \"0\" ]]; then\n\tgit merge upstream-$BRANCH 2\u003e\u00261\n    GIT_EDITOR=/bin/true git merge --continue 2\u003e\u00261\n    git push origin 2\u003e\u00261\nelse\n\t\u003e\u00262 echo \"Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually.\"\n    exit 1\nfi"
        "OctopusUseBundledTooling" = "False"
      }

      container {
        feed_id = data.octopusdeploy_feeds.docker.feeds[0].id
        image   = "octopusdeploy/worker-tools:5.0.0-ubuntu.22.04"
      }

      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      package {
        name                      = "gh"
        package_id                = "gh"
        acquisition_location      = "Server"
        extract_during_deployment = false
        feed_id                   = "${data.octopusdeploy_feeds.built_in_feed.feeds[0].id}"
        properties                = { Extract = "True", Purpose = "", SelectionMode = "immediate" }
      }
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}

