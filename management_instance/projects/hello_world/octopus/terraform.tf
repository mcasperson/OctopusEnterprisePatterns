terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
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

resource "octopusdeploy_project_group" "project_group_hello_world" {
  name = "Hello World"
}

data "octopusdeploy_channels" "channel_default" {
  ids          = null
  partial_name = "Default"
  skip         = 0
  take         = 1
}

data "octopusdeploy_lifecycles" "lifecycle_default_lifecycle" {
  ids          = null
  partial_name = "Default Lifecycle"
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

resource "octopusdeploy_project" "project_provision_hello_world" {
  name                                 = "Provision Hello World"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = ""
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_default_lifecycle.lifecycles[0].id}"
  project_group_id                     = "${octopusdeploy_project_group.project_group_hello_world.id}"
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.docker_hub.library_variable_sets[0].id
  ]
  tenanted_deployment_participation    = "Tenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_variable" "amazon_web_services_account_variable" {
  owner_id  = octopusdeploy_project.project_provision_hello_world.id
  type      = "AmazonWebServicesAccount"
  name      = "AWS"
  value     = data.octopusdeploy_accounts.aws.accounts[0].id
}

resource "octopusdeploy_deployment_process" "deployment_process_project_provision_hello_world" {
  project_id = "${octopusdeploy_project.project_provision_hello_world.id}"

  step {
    condition           = "Success"
    name                = "Clear Deployment Process"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Clear Deployment Process"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
        "Octopus.Action.Script.ScriptBody" = "declare -a arr=(\"Hello World\")\n\nfor i in \"$${arr[@]}\"\ndo\n  DEPLOYMENT_PROCESS_ID=$(curl --silent -G --data-urlencode \"name=$i\" -H \"X-Octopus-ApiKey: #{Tenant.Octopus.ApiKey}\" #{Tenant.Octopus.Server}/api/#{Tenant.Octopus.SpaceId}/projects | jq -r \".Items[0].DeploymentProcessId\")\n  if [[ -n \"$DEPLOYMENT_PROCESS_ID\" \u0026\u0026 \"$DEPLOYMENT_PROCESS_ID\" != \"null\" ]]; then\n    echo \"Emptying project deploy process $DEPLOYMENT_PROCESS_ID for project $i\"\n    DEPLOYMENT_PROCESS=$(curl --silent -H \"X-Octopus-ApiKey: #{Tenant.Octopus.ApiKey}\" #{Tenant.Octopus.Server}/api/#{Tenant.Octopus.SpaceId}/deploymentprocesses/$${DEPLOYMENT_PROCESS_ID})\n    EMPTY_DEPLOYMENT_PROCESS=$(echo $${DEPLOYMENT_PROCESS} | jq 'del(.Steps[])')\n    NEW_DEPLOYMENT_PROCESS=$(curl --silent -X PUT -d \"$${EMPTY_DEPLOYMENT_PROCESS}\" -H \"Content-Type: application/json\" -H \"X-Octopus-ApiKey: #{Tenant.Octopus.ApiKey}\" #{Tenant.Octopus.Server}/api/#{Tenant.Octopus.SpaceId}/deploymentprocesses/$${DEPLOYMENT_PROCESS_ID})\n  fi\ndone"
      }
      environments                       = []
      excluded_environments              = []
      channels                           = []
      tenant_tags                        = []
      features                           = []
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
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "True"
        "Octopus.Action.Terraform.TemplateDirectory" = "managed_instances/projects/hello_world"
        "Octopus.Action.Terraform.AllowPluginDownloads" = "True"
        "Octopus.Action.Terraform.AzureAccount" = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.PlanJsonOutput" = "False"
        "Octopus.Action.Script.ScriptSource" = "Package"
        "Octopus.Action.Terraform.GoogleCloudAccount" = "False"
        "Octopus.Action.Package.DownloadOnTentacle" = "False"
        "Octopus.Action.Terraform.AdditionalInitParams" = "-backend-config=\"key=managed_instance_project_hello_world\" -backend-config=\"bucket=${var.bucket_name}\" -backend-config=\"region=${var.bucket_region}\""
        "Octopus.Action.Terraform.AdditionalActionParams" = "-var=octopus_server=#{Tenant.Octopus.Server} -var=octopus_apikey=#{Tenant.Octopus.ApiKey} -var=octopus_space_id=#{Tenant.Octopus.SpaceId}"
        "Octopus.Action.Terraform.Workspace" = "#{Octopus.Deployment.Tenant.Name | ToLower}"
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

data "octopusdeploy_worker_pools" "workerpool_hosted_ubuntu" {
  name = "Hosted Ubuntu"
  ids  = null
  skip = 0
  take = 1
}

