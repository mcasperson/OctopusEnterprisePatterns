terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.11.2" }
  }
}

resource "octopusdeploy_github_repository_feed" "feed_github" {
  name                                 = "GitHub"
  password                             = "${var.feed_github_password}"
  feed_uri                             = "https://api.github.com"
  download_attempts                    = 5
  download_retry_backoff_seconds       = 10
  package_acquisition_location_options = ["Server", "ExecutionTarget"]
}

variable "feed_github_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The password used by the feed GitHub"
}