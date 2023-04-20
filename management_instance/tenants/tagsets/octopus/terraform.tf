terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_tag_set" "tagset_type" {
  name        = "type"
  description = "Tenant type tags"
  sort_order  = 0
}

resource "octopusdeploy_tag" "tag_managed_instance" {
  name        = "managed_instance"
  color       = "#008000"
  description = "Managed Instance"
  sort_order  = 0
  tag_set_id = octopusdeploy_tag_set.tagset_type.id
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