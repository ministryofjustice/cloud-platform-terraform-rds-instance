provider "aws" {
  region = "eu-west-1"
}

/*
 * When using this module through the cloud-platform-environments, the following
 * two variables are automatically supplied by the pipeline.
 *
 */

variable "cluster_name" {}

variable "cluster_state_bucket" {}

module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=2.0"

  cluster_name               = "${var.cluster_name}"
  cluster_state_bucket       = "${var.cluster_state_bucket}"
  team_name                  = "example-repo"
  db_allocated_storage       = "100"
  db_engine                  = "postgres"
  db_engine_version          = "10.4"
  db_instance_class          = "db.t2.small"
  db_backup_retention_period = 10
  db_storage_type            = "io1"
  db_iops                    = "1000"
  business-unit              = "example-bu"
  application                = "exampleapp"
  is-production              = "false"
  environment-name           = "development"
  infrastructure-support     = "example-team@digtal.justice.gov.uk"
}
