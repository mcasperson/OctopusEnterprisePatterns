terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
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
  default     = "Azure Web App"
}

variable "role_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the new target role."
  default     = "octopub-webapp"
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

data "octopusdeploy_feeds" "maven" {
  feed_type    = "Maven"
  partial_name = "Sales Maven Feed"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "security" {
  partial_name = "Security"
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
  partial_name = var.existing_project_group
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project_group" "project_group" {
  count = var.existing_project_group == "" ? 1 : 0
  name  = "Azure Web App"
}

resource "octopusdeploy_project" "project" {
  name                                 = var.project_name
  description                          = "A project that is created by Terraform but then able to be edited."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_devsecops.lifecycles[0].id}"
  project_group_id                     = var.existing_project_group == "" ? octopusdeploy_project_group.project_group[0].id : data.octopusdeploy_project_groups.project_group.project_groups[0].id
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_variable" "cloud_discovery" {
  owner_id = octopusdeploy_project.project.id
  type     = "AzureAccount"
  name     = "Octopus.Azure.Account"
  value    = data.octopusdeploy_accounts.azure.accounts[0].id
}

resource "octopusdeploy_deployment_process" "deployment_process" {
  lifecycle {
    ignore_changes = [
      step,
    ]
  }

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
        "Octopus.Action.Script.Syntax"       = "Bash"
        "Octopus.Action.Azure.AccountId"     = data.octopusdeploy_accounts.azure.accounts[0].id
        "Octopus.Action.Script.ScriptBody"   = "NOW=$(date +%s)\nCREATED=$${NOW}\nRESOURCE_NAME=#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Project.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Environment.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}\n\n# az tag list --resource-id /subscriptions/#{Octopus.Action.Azure.SubscriptionId}/resourcegroups/$${RESOURCE_NAME}rg\n\n# Test if the resource group exists\nEXISTING_RG=$(az group list --query \"[?name=='$${RESOURCE_NAME}-rg']\")\nLENGTH=$(echo $${EXISTING_RG} | jq '. | length')\n\nif [[ $LENGTH == \"0\" ]]\nthen\n\techo \"Creating new resource group\"\n\taz group create -l westus -n \"$${RESOURCE_NAME}-rg\" --tags LifeTimeInDays=7 Created=$${NOW}\nelse\n\techo \"Resource group already exists\"\nfi\n\nEXISTING_SP=$(az appservice plan list --resource-group \"$${RESOURCE_NAME}-rg\")\nLENGTH=$(echo $${EXISTING_SP} | jq '. | length')\nif [[ $LENGTH == \"0\" ]]\nthen\n\techo \"Creating new service plan\"\n\taz appservice plan create \\\n      --sku B1 \\\n      --name \"$${RESOURCE_NAME}-sp\" \\\n      --resource-group \"$${RESOURCE_NAME}-rg\" \\\n      --is-linux\nelse\n\techo \"Service plan already exists\"\nfi\n\nEXISTING_WA=$(az webapp list --resource-group \"$${RESOURCE_NAME}-rg\")\nLENGTH=$(echo $${EXISTING_WA} | jq '. | length')\nif [[ $LENGTH == \"0\" ]]\nthen\n\techo \"Creating new web app\"\n\taz webapp create \\\n      --resource-group \"$${RESOURCE_NAME}-rg\" \\\n      --plan \"$${RESOURCE_NAME}-sp\" \\\n      --name \"$${RESOURCE_NAME}-wa\" \\\n      --deployment-container-image-name nginx \\\n      --tags \\\n      \toctopus-environment=\"#{Octopus.Environment.Name}\" \\\n        octopus-space=\"##{Octopus.Space.Name}\" \\\n        octopus-project=\"##{Octopus.Project.Name}\" \\\n        octopus-role=\"${var.role_name}\"\nelse\n\techo \"Web App already exists\"\nfi\n\nHOST=$(az webapp list --resource-group \"$${RESOURCE_NAME}-rg\"  --query \"[].{hostName: defaultHostName}\" | jq -r '.[0].hostName')\nset_octopusvariable \"HostName\" $HOST\nwrite_highlight \"[https://$HOST](http://$HOST)\""
        "OctopusUseBundledTooling"           = "False"
      }

      container {
        feed_id = data.octopusdeploy_feeds.docker.feeds[0].id
        image   = "octopusdeploy/worker-tools:5.0.0-ubuntu.22.04"
      }

      environments          = []
      excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition           = "Success"
    name                = "Deploy Web App"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AzureAppService"
      name                               = "Deploy Web App"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "OctopusUseBundledTooling"                  = "False"
        "Octopus.Action.Azure.DeploymentType"       = "Container"
        "Octopus.Action.Package.DownloadOnTentacle" = "False"
      }
      environments          = []
      excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
      channels              = []
      tenant_tags           = []

      primary_package {
        package_id           = "octopussamples/octopub"
        acquisition_location = "NotAcquired"
        feed_id              = data.octopusdeploy_feeds.docker.feeds[0].id
        properties           = { SelectionMode = "immediate" }
      }

      features = [
        "Octopus.Features.JsonConfigurationVariables", "Octopus.Features.ConfigurationTransforms",
        "Octopus.Features.SubstituteInFiles"
      ]
    }

    properties   = {}
    target_roles = [var.role_name]
  }

  step {
    condition           = "Success"
    name                = "End-to-end Test with Cypress"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "End-to-end Test with Cypress"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptBody"   = "cd octopub-cypress\n\nNO_COLOR=1 CYPRESS_BASE_URL=https://#{Octopus.Action[Create Web App].Output.HostName}/ cypress run 2\u003e\u00261\nRESULT=$?\nif [[ -f mochawesome.html ]]\nthen\n  inline-assets mochawesome.html selfcontained.html\n  new_octopusartifact \"$${PWD}/selfcontained.html\" \"selfcontained.html\"\nfi\nif [[ -d cypress/screenshots ]]\nthen\n  zip -r screenshots.zip cypress/screenshots\n  new_octopusartifact \"$${PWD}/screenshots.zip\" \"screenshots.zip\"\nfi\n\nif [[ -d cypress/videos ]]\nthen\n  zip -r videos.zip cypress/videos\n  new_octopusartifact \"$${PWD}/videos.zip\" \"videos.zip\"\nfi\n\nexit $${RESULT}"
        "OctopusUseBundledTooling"           = "False"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "Bash"
      }

      container {
        feed_id = data.octopusdeploy_feeds.docker.feeds[0].id
        image   = "octopussamples/cypress-included:12.8.1"
      }

      environments          = []
      excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
      channels              = []
      tenant_tags           = []

      package {
        name                      = "octopub-cypress"
        package_id                = "com.octopus:octopub-cypress"
        acquisition_location      = "Server"
        extract_during_deployment = false
        feed_id                   = data.octopusdeploy_feeds.maven.feeds[0].id
        properties                = { Extract = "True", Purpose = "", SelectionMode = "immediate" }
      }
      features = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition           = "Success"
    name                = "Check for Vulnerabilities"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Check for Vulnerabilities"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = true
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_hosted_ubuntu.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.SubstituteInFiles.Enabled" = "True"
        "Octopus.Action.Script.ScriptBody"         = "echo \"##octopus[stdout-verbose]\"\ndocker pull appthreat/dep-scan\necho \"##octopus[stdout-default]\"\n\nTIMESTAMP=$(date +%s%3N)\nSUCCESS=0\nfor x in $(find . -name bom.xml -type f -print); do\n    echo \"Scanning $${x}\"\n\n    # Delete any existing report file\n    if [[ -f \"$PWD/depscan-bom.json\" ]]; then\n      rm \"$PWD/depscan-bom.json\"\n    fi\n\n    # Generate the report, capturing the output, and ensuring $? is set to the exit code\n    OUTPUT=$(bash -c \"docker run --rm -v \\\"$PWD:/app\\\" appthreat/dep-scan --bom \\\"/app/$${x}\\\" --type bom --report_file /app/depscan.json; exit \\$?\" 2\u003e\u00261)\n\n    # Success is set to 1 if the exit code is not zero\n    if [[ $? -ne 0 ]]; then\n        SUCCESS=1\n    fi\n\n    # Print the output stripped of ANSI colour codes\n    echo -e \"$${OUTPUT}\" | sed 's/\\x1b\\[[0-9;]*m//g'\ndone\n\nset_octopusvariable \"VerificationResult\" $SUCCESS\n\nif [[ $SUCCESS -ne 0 ]]; then\n  \u003e\u00262 echo \"Critical vulnerabilities were detected\"\nfi\n\nexit 0\n"
        "Octopus.Action.Script.ScriptSource"       = "Inline"
        "Octopus.Action.Script.Syntax"             = "Bash"
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []

      package {
        name                      = "sbom"
        package_id                = "com.octopus:octopub-sbom"
        acquisition_location      = "Server"
        extract_during_deployment = false
        feed_id                   = data.octopusdeploy_feeds.maven.feeds[0].id
        properties                = { Extract = "True" }
      }
      features = ["Octopus.Features.SubstituteInFiles"]
    }

    properties   = {}
    target_roles = []
  }
}