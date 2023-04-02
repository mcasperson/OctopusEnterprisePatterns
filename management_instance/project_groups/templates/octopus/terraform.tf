terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.1" }
  }
}

resource "octopusdeploy_project_group" "project_group" {
  name = "Project Templates"
}
