provider "aws" {
  region = "eu-west-1"
}

module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance"

  /*
   * When using this module through the cloud-platform-environments, the
   * following two values are automatically supplied by the pipeline as
   * variables.
   *
   */
  // cluster_name           = "cloud-platform-live-0"
  // cluster_state_bucket   = "cloud-platform-cluster-state-bucket"

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
