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

resource "octopusdeploy_project_group" "project_group" {
  name = "Azure Web App"
}

data "octopusdeploy_lifecycles" "lifecycle_default_lifecycle" {
  ids          = null
  partial_name = "Default Lifecycle"
  skip         = 0
  take         = 1
}

data "octopusdeploy_accounts" "azure" {
  partial_name = "Azure"
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

resource "octopusdeploy_project" "project" {
  name                                 = "Provision Azure Web App"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = ""
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_default_lifecycle.lifecycles[0].id}"
  project_group_id                     = "${octopusdeploy_project_group.project_group.id}"
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Tenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_deployment_process" "deployment_process" {
  project_id = "${octopusdeploy_project.project.id}"

  step {
    condition           = "Success"
    name                = "Create Web App"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AzurePowerShell"
      name                               = "Create Web App"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "Bash"
        "Octopus.Action.Azure.AccountId" = data.octopusdeploy_accounts.azure.accounts[0].id
        "Octopus.Action.Script.ScriptBody" = "NOW=$(date +%s)\nCREATED=$${NOW}\nRESOURCE_NAME=#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Project.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Environment.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}\n\n# az tag list --resource-id /subscriptions/#{Octopus.Action.Azure.SubscriptionId}/resourcegroups/$${RESOURCE_NAME}rg\n\n# Test if the resource group exists\nEXISTING_RG=$(az group list --query \"[?name=='$${RESOURCE_NAME}-rg']\")\nLENGTH=$(echo $${EXISTING_RG} | jq '. | length' \u003e /dev/null)\n\nif [[ $LENGTH != \"0\" ]]\nthen\n\techo \"Creating new resource group\"\n\taz group create -l westus -n \"$${RESOURCE_NAME}-rg\" --tags LifeTimeInDays=7 Created=$${NOW}\nelse\n\techo \"Resource group already exists\"\nfi\n\nEXISTING_SP=$(az appservice plan list --resource-group \"$${RESOURCE_NAME}-rg\")\nLENGTH=$(echo $${EXISTING_SP} | jq '. | length' \u003e /dev/null)\nif [[ $LENGTH != \"0\" ]]\nthen\n\techo \"Creating new service plan\"\n\taz appservice plan create \\\n      --sku B1 \\\n      --name \"$${RESOURCE_NAME}-sp\" \\\n      --resource-group \"$${RESOURCE_NAME}-rg\" \\\n      --is-linux\nelse\n\techo \"Service plan already exists\"\nfi\n\nEXISTING_WA=$(az webapp list --resource-group \"$${RESOURCE_NAME}-rg\")\nLENGTH=$(echo $${EXISTING_WA} | jq '. | length' \u003e /dev/null)\nif [[ $LENGTH != \"0\" ]]\nthen\n\techo \"Creating new web app\"\n\taz webapp create \\\n      --resource-group \"$${RESOURCE_NAME}-rg\" \\\n      --plan \"$${RESOURCE_NAME}-sp\" \\\n      --name \"$${RESOURCE_NAME}-wa\" \\\n      --deployment-container-image-name nginx \nelse\n\techo \"Web App already exists\"\nfi"
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
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}