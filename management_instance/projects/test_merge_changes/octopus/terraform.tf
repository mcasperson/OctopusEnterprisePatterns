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
  skip         = 0
  take         = 1
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

data "octopusdeploy_accounts" "aws" {
  partial_name = "AWS Account"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project" "project" {
  name                                 = "Azure Web App (Test Merge Changes)"
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
  tenanted_deployment_participation = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_variable" "aws" {
  owner_id     = "${octopusdeploy_project.project.id}"
  value        = data.octopusdeploy_accounts.aws.accounts[0].id
  name         = "AWS"
  type         = "AmazonWebServicesAccount"
  is_sensitive = false

  scope {
    actions      = []
    channels     = []
    environments = []
    machines     = []
    roles        = null
    tenant_tags  = null
  }
  depends_on = []
}

resource "octopusdeploy_deployment_process" "deployment_process" {
  project_id = "${octopusdeploy_project.project.id}"

  step {
    condition           = "Success"
    name                = "Test Merge Deployment Process"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AwsRunScript"
      name                               = "Test Merge Deployment Process"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Aws.Region"                 = "ap-southeast-2"
        "Octopus.Action.AwsAccount.UseInstanceRole" = "False"
        "Octopus.Action.AwsAccount.Variable"        = "AWS"
        "Octopus.Action.Aws.AssumeRole"             = "False"
        "OctopusUseBundledTooling"                  = "False"
        "Octopus.Action.Script.ScriptSource"        = "Inline"
        "Octopus.Action.Script.Syntax"              = "Bash"
        "Octopus.Action.Script.ScriptBody"          = <<EOT
        TEMPLATE_REPO=https://github.com/mcasperson/OctopusEnterprisePatternsAzureWebAppCaCTemplate.git
        BRANCH=octopus-vcs-conversion

        echo "##octopus[stdout-verbose]"

        printf 'terraform {\n
          backend "s3" {\n
          }\n
        }' > backend.tf

        cat backend.tf

        terraform init \
          -no-color \
          -backend-config="key=managed_instance_project_azure_web_app_cac" \
          -backend-config="bucket=octopus-enterprise-patterns-state" \
          -backend-config="region=ap-southeast-2"

        for i in $(terraform workspace list|sed 's/*//g'); do
            echo "##octopus[stdout-verbose]"

            if [[ $i == "default" ]]; then
                continue
            fi

            terraform workspace select $${i}

            URL=$(terraform output -raw cac_url)

            if [[ $? != "0" ]]; then
                echo "Could not find the state variable 'cac_url' in workspace $${i}. Skipping this workspace."
                continue
            fi

            SPACE=$(terraform output -raw space_name)

            if [[ $? != "0" ]]; then
                echo "Could not find the state variable 'space_name' in workspace $${i}. Skipping this workspace."
                continue
            fi

            PROJECT_NAME=$(terraform output -raw project_name)

            if [[ $? != "0" ]]; then
                echo "Could not find the state variable 'project_name' in workspace $${i}. Skipping this workspace."
                continue
            fi

            mkdir $i
            pushd $i

            git clone $URL ./ 2>&1
            git remote add upstream $${TEMPLATE_REPO} 2>&1
            git fetch --all 2>&1
            git checkout -b upstream-$${BRANCH} upstream/$${BRANCH} 2>&1
            git checkout -b $BRANCH origin/$BRANCH 2>&1

            # Test if the template branch needs to be merged into the project branch
            MERGE_BASE=$(git merge-base $${BRANCH} upstream-$${BRANCH})
            MERGE_SOURCE_CURRENT_COMMIT=$(git rev-parse upstream-$${BRANCH})
            if [[ $${MERGE_BASE} = $${MERGE_SOURCE_CURRENT_COMMIT} ]]
            then
              UP_TO_DATE=0
            else
              UP_TO_DATE=1
            fi

            # Test the results of a merge with the upstream branch
            git merge --no-commit upstream-$${BRANCH} 2>&1
            MERGE_RESULT=$?

            popd

            echo "##octopus[stdout-default]"

            if [[ $${UP_TO_DATE} == "0" ]]; then
              echo "\"$${PROJECT_NAME}\" in \"$${SPACE}\" is up to date with the upstream template."
            elif [[ $${MERGE_RESULT} != "0" ]]; then
                echo "\"$${PROJECT_NAME}\" in \"$${SPACE}\" has a merge conflict with the changes in the upstream template."
            else
                echo "\"$${PROJECT_NAME}\" in \"$${SPACE}\" can be merged with the changes int the upstream template."
            fi
        done
        EOT
        "OctopusUseBundledTooling"                  = "False"
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
      features = []
    }

    properties   = {}
    target_roles = []
  }
}

