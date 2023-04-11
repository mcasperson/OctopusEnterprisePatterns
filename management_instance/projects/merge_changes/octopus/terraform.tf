terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.2" }
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
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle.lifecycles[0].id
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
  project_id = octopusdeploy_project.project.id

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
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
        "Octopus.Action.Script.ScriptBody" = <<EOT
NEW_REPO="#{Octopus.Deployment.Tenant.Name | ToLower}-#{Project.Name | ToLower | Replace "[^a-zA-Z0-9]" "-"}"
TEMPLATE_REPO=https://github.com/mcasperson/OctopusEnterprisePatternsAzureWebAppCaCTemplate.git
PROJECT_DIR=.octopus/azure-web-app
BRANCH=octopus-vcs-conversion

cd gh/gh_2.25.1_linux_amd64/bin

# Fix executable flag
chmod +x gh

# Log into GitHub
cat <<< #{Tenant.CaC.Password} | ./gh auth login --with-token

# Use the github cli as the credential helper
./gh auth setup-git

# Replace these with some sensible values
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1

# Clone the template repo to test for a step template reference
mkdir template
pushd template
git clone $${TEMPLATE_REPO} ./
git checkout -b $BRANCH origin/$${BRANCH} 2>&1
grep -Fxq "ActionTemplates" "$${PROJECT_DIR}/deployment_process.ocl"
if [[ $? != "0" ]]; then
  >&2 echo "Template repo references a step template. Step templates can not be merged across spaces or instances."
  exit 1
fi
popd

# Merge the template changes
git clone #{Tenant.CaC.Url}/#{Tenant.CaC.Org}/$${NEW_REPO}.git 2>&1
cd $${NEW_REPO}
git remote add upstream $${TEMPLATE_REPO} 2>&1
git fetch --all 2>&1
git checkout -b upstream-$${BRANCH} upstream/$${BRANCH} 2>&1
git checkout -b $${BRANCH} origin/$${BRANCH} 2>&1
git merge --no-commit upstream-$${BRANCH} 2>&1

if [[ $? == "0" ]]; then
    git merge upstream-$${BRANCH} 2>&1

    # Test that a merge is being performed
    git merge HEAD &> /dev/null
    if [[ $? -ne 0 ]]; then
      GIT_EDITOR=/bin/true git merge --continue 2>&1
      git push origin 2>&1
    fi
else
    >&2 echo "Template repo branch could not be automatically merged into project branch. This merge will need to be resolved manually."
    exit 1
fi
EOT
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
        feed_id                   = data.octopusdeploy_feeds.built_in_feed.feeds[0].id
        properties                = { Extract = "True", Purpose = "", SelectionMode = "immediate" }
      }
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}

