  provider "aws" {
  region = "eu-west-1"
}
  
  module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=master"
  
  team_name              = "example-repo"
  db_allocated_storage   = 20
  db_engine              = "mysql"
  db_engine_version      = 5.7
  db_instance_class      = "db.t2.small"
  db_retention_period    = 10
  db_port                = 3306
  db_storage_type        = "io1"
  db_iops                = 1000
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "example-team@digtal.justice.gov.uk"

  }