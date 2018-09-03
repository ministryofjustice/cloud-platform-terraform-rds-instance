provider "aws" {
  region = "eu-west-1"
}

module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance"

  team_name                  = "example-repo"
  db_allocated_storage       = "100"
  db_engine                  = "mysql"
  db_engine_version          = "5.7.17"
  db_instance_class          = "db.t2.small"
  db_backup_retention_period = 10
  db_storage_type            = "io1"
  db_iops                    = "1000"
  db_vpc_security_group_ids  = ["sg-7e8cf203", "sg-7e8cf203"]
  db_db_subnet_groups        = ["subnet-7293103a", "subnet-7bf10c21", "subnet-de00b3b8"]
  business-unit              = "example-bu"
  application                = "exampleapp"
  is-production              = "false"
  environment-name           = "development"
  infrastructure-support     = "example-team@digtal.justice.gov.uk"
}
