/*
 * When using this module through the cloud-platform-environments,
 * this variable is automatically supplied by the pipeline.
 *
*/

variable "cluster_name" {}

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
*/

module "rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=5.16"

  cluster_name           = var.cluster_name
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  namespace              = "example-ns"
  environment-name       = "example-env"
  infrastructure-support = "example-team"

  # enable performance insights
  performance_insights_enabled = true

  db_engine                   = "sqlserver-ex"
  db_engine_version           = "15.00.4073.23.v1"
  db_instance_class           = "db.t3.medium"
  db_allocated_storage        = 32
  rds_family                  = "sqlserver-ex-15.0"
  allow_minor_version_upgrade = true
  allow_major_version_upgrade = false

  providers = {
    # Can be either "aws.london" or "aws.ireland"
    aws = aws.london
  }
}

resource "kubernetes_secret" "rds" {
  metadata {
    name      = "rds-instance-output"
    namespace = "example-ns"
  }

  data = {
    rds_instance_endpoint = module.rds.rds_instance_endpoint
    database_username     = module.rds.database_username
    database_password     = module.rds.database_password
    rds_instance_address  = module.rds.rds_instance_address
    access_key_id         = module.rds.access_key_id
    secret_access_key     = module.rds.secret_access_key
  }
}
