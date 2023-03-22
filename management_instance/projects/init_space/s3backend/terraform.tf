terraform {
  backend "s3" {
  }
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

module "octopus" {
  source = "../octopus"
  octopus_server = var.octopus_server
  octopus_apikey = var.octopus_apikey
  octopus_space_id = var.octopus_space_id
  bucket_name = var.bucket_name
  bucket_region = var.bucket_region
}
