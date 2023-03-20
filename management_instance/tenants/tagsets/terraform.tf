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

resource "octopusdeploy_tag_set" "tagset_region" {
  name        = "region"
  description = "Region tags"
  sort_order  = 0
}

resource "octopusdeploy_tag" "tag_europe" {
  name        = "eu"
  color       = "#008000"
  description = "Europe"
  sort_order  = 0
  tag_set_id = octopusdeploy_tag_set.tagset_region.id
}

resource "octopusdeploy_tag" "tag_america" {
  name        = "us"
  color       = "#000080"
  description = "United States"
  sort_order  = 0
  tag_set_id = octopusdeploy_tag_set.tagset_region.id
}