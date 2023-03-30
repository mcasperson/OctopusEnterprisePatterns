terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
}

variable "bucket_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The S3 bucket used to hold the Terraform state."
}

variable "bucket_region" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The S3 bucket used to hold the Terraform state."
}

data "octopusdeploy_project_groups" "project_group" {
  partial_name = "Azure Web App"
  skip         = 0
  take         = 1
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

data "octopusdeploy_feeds" "github" {
  feed_type    = "GitHub"
  partial_name = "Github"
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

data "octopusdeploy_library_variable_sets" "cac" {
  partial_name = "Config As Code"
  skip = 0
  take = 1
}

data "octopusdeploy_accounts" "aws" {
  partial_name = "AWS Account"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "docker" {
  feed_type    = "Docker"
  partial_name = "Docker"
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

data "octopusdeploy_worker_pools" "workerpool_hosted_ubuntu" {
  name = "Hosted Ubuntu"
  ids  = null
  skip = 0
  take = 1
}

resource "octopusdeploy_project" "project" {
  name                                 = "Provision Unmanaged Azure Web App (CaC)"
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
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.cac.library_variable_sets[0].id
  ]
  tenanted_deployment_participation    = "Tenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_variable" "amazon_web_services_account_variable" {
  owner_id  = octopusdeploy_project.project.id
  type      = "AmazonWebServicesAccount"
  name      = "AWS"
  value     = data.octopusdeploy_accounts.aws.accounts[0].id
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
    name                = "Fork the Template Repo"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Fork the Template Repo"
      notes                              = "This script \"forks\" the template repo to create the repo that the new project will save its CaC code in."
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptBody" = "# All of this is to essentially fork a repo within the same organisation\n\nNEW_REPO=\"#{Octopus.Deployment.Tenant.Name | ToLower}-#{Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}\"\nTEMPLATE_REPO=https://github.com/mcasperson/OctopusEnterprisePatternsAzureWebAppCaCTemplate.git\nBRANCH=octopus-vcs-conversion\n\ncd gh/gh_2.25.1_linux_amd64/bin\n\n# Fix executable flag\nchmod +x gh\n\n# Log into GitHub\ncat \u003c\u003c\u003c #{Tenant.CaC.Password} | ./gh auth login --with-token\n\n# Use the github cli as the credential helper\n./gh auth setup-git\n\n# Attempt to view the template repo\n./gh repo view $NEW_REPO \u003e /dev/null 2\u003e\u00261\n\nif [[ $? != \"0\" ]]; then \n\twrite_error \"Could not find the template repo at $TEMPLATE_REPO\"\n    exit 1\nfi\n\n# Attempt to view the new repo\n./gh repo view $NEW_REPO \u003e /dev/null 2\u003e\u00261\n\necho \"##octopus[stdout-verbose]\"\n\nif [[ $? != \"0\" ]]; then \n    # If we could not view the repo, assume it needs to be created.\n    REPO_URL=$(./gh repo create $NEW_REPO --public --clone --add-readme)\nelse\n\t# Otherwise clone it.\n\tgit clone #{Tenant.CaC.Url}$NEW_REPO 2\u003e\u00261\nfi\n\n# Enter the repo.\ncd $NEW_REPO\n\n# Link the template repo as a new remote.\ngit remote add upstream $TEMPLATE_REPO 2\u003e\u00261\n\n# Fetch all the code from the upstream remots.\ngit fetch --all 2\u003e\u00261\n\n# Test to see if the remote branch already exists.\ngit show-branch remotes/origin/$BRANCH 2\u003e\u00261\n\nif [ $? == \"0\" ]; then\n  # Checkout the remote branch.\n  git checkout -b $BRANCH origin/$BRANCH 2\u003e\u00261\n\n  # If the .octopus directory exists, assume this repo has already been prepared.\n  if [ -d \".octopus\" ]; then\n      echo \"##octopus[stdout-default]\"\n      echo \"The repo has already been forked.\"\n      exit 0\n  fi\nfi\n\n# Create a new branch representing the forked main branch.\ngit checkout -b $BRANCH 2\u003e\u00261\n\n# Hard reset it to the template main branch.\ngit reset --hard upstream/$BRANCH 2\u003e\u00261\n\n# Push the changes.\ngit push origin $BRANCH 2\u003e\u00261\n\necho \"##octopus[stdout-default]\"\necho \"Repo was forked from $TEMPLATE_REPO to #{Tenant.CaC.Url}$NEW_REPO\""
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
      }
      environments                       = []
      excluded_environments              = []
      channels                           = []
      tenant_tags                        = []

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

  step {
    condition           = "Success"
    name                = "Deploy Octopus Resources"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Octopus Resources"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Terraform.ManagedAccount": "AWS",
        "Octopus.Action.AwsAccount.UseInstanceRole" = "False"
        "Octopus.Action.Aws.AssumeRole" = "False"
        "Octopus.Action.Aws.Region" = "ap-southeast-2"
        "Octopus.Action.AwsAccount.Variable" = "AWS"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount" = "False"
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "False"
        "Octopus.Action.Terraform.TemplateDirectory" = "managed_instances/projects/azure_web_app_cac/s3backend"
        "Octopus.Action.Terraform.AllowPluginDownloads" = "True"
        "Octopus.Action.Terraform.AzureAccount" = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.PlanJsonOutput" = "False"
        "Octopus.Action.Script.ScriptSource" = "Package"
        "Octopus.Action.Terraform.GoogleCloudAccount" = "False"
        "Octopus.Action.Package.DownloadOnTentacle" = "False"
        "Octopus.Action.Terraform.AdditionalInitParams" = "-backend-config=\"key=managed_instance_project_azure_web_app_cac\" -backend-config=\"bucket=${var.bucket_name}\" -backend-config=\"region=${var.bucket_region}\""
        "Octopus.Action.Terraform.AdditionalActionParams" = "-var=octopus_server=#{Tenant.Octopus.Server} -var=octopus_apikey=#{Tenant.Octopus.ApiKey} -var=octopus_space_id=#{Tenant.Octopus.SpaceId} -var=cac_url=#{Tenant.CaC.Url}#{Octopus.Deployment.Tenant.Name | ToLower}-#{Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}.git \"-var=existing_project_group=Default Project Group\" \"-var=project_name=#{Project.Name}\""
        "Octopus.Action.Terraform.Workspace" = "#{Octopus.Deployment.Tenant.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}-#{Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}"
      }
      environments                       = []
      excluded_environments              = []
      channels                           = []
      tenant_tags                        = []

      primary_package {
        package_id           = "mcasperson/OctopusEnterprisePatterns"
        acquisition_location = "Server"
        feed_id              = data.octopusdeploy_feeds.github.feeds[0].id
        properties           = { SelectionMode = "immediate" }
      }

      container {
        feed_id = data.octopusdeploy_feeds.docker.feeds[0].id
        image   = "octopusdeploy/worker-tools:5.0.0-ubuntu.22.04"
      }

      features = []
    }

    properties   = {}
    target_roles = []
  }
}
