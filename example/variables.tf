/*
 * When using this module through the cloud-platform-environments,
 * the next 3 variables are automatically supplied by the pipeline.
 *
*/
variable "cluster_name" {
}
variable "kubernetes_cluster" {
}
variable "github_token" {
  description = "Required by the github terraform provider"
  default     = ""
}

variable "application" {
  description = "Name of Application you are deploying"
  default     = "example-app"
}

variable "namespace" {
  default = "example-team"
}

variable "business_unit" {
  description = "Area of the MOJ responsible for the service."
  default     = "Example"
}

variable "team_name" {
  description = "The name of your development team"
  default     = "example"
}

variable "environment" {
  description = "The type of environment you're deploying to."
  default     = "development"
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form team-email."
  default     = "example@digital.justice.gov.uk"
}

variable "is_production" {
  default = "false"
}

variable "slack_channel" {
  description = "Team slack channel to use if we need to contact your team"
  default     = "example"
}

variable "github_owner" {
  description = "Required by the github terraform provider"
  default     = "ministryofjustice"
}
