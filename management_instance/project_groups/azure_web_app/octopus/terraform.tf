terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_project_group" "project_group" {
  name = "Azure Web App"
}
