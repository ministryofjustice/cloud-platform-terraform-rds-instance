/*
 * When using this module through the cloud-platform-environments, the following
 * two variables are automatically supplied by the pipeline.
 *
 */

variable "cluster_name" {
}

variable "cluster_state_bucket" {
}

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */

# IMP NOTE: Updating to module version 5.3, existing database password will be rotated.
# Make sure you restart your pods which use this RDS secret to avoid any down time.

module "example_team_rds" {
  source               = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=5.6"
  cluster_name         = var.cluster_name
  cluster_state_bucket = var.cluster_state_bucket
  team_name            = "example-repo"
  business-unit        = "example-bu"
  application          = "exampleapp"
  is-production        = "false"

  # If the rds_name is not specified a random name will be generated ( cp-* )
  # Changing the RDS name requires the RDS to be re-created (destroy + create)
  # rds_name             = "my-rds-name" 

  # enable performance insights
  performance_insights_enabled = true

  # change the postgres version as you see fit.
  db_engine_version      = "10"
  environment-name       = "development"
  infrastructure-support = "example-team@digital.justice.gov.uk"

  # rds_family should be one of: postgres9.4, postgres9.5, postgres9.6, postgres10, postgres11
  # Pick the one that defines the postgres version the best
  rds_family = "postgres10"

  # Some engines can't apply some parameters without a reboot(ex postgres9.x cant apply force_ssl immediate). 
  # You will need to specify "pending-reboot" here, as default is set to "immediate".
  # db_parameter = [
  #   {
  #     name         = "rds.force_ssl"
  #     value        = "0"
  #     apply_method = "pending-reboot"
  #   }
  # ]

  # use "allow_major_version_upgrade" when upgrading the major version of an engine
  allow_major_version_upgrade = "true"

  providers = {
    # Can be either "aws.london" or "aws.ireland"
    aws = aws.london
  }
}

# To create a read replica, use the below code and update the values to specify the RDS instance 
# from which you are replicating. In this example, we're assuming that example_team_rds is the 
# source RDS instance,and example-team-read-replica is the replica we are creating.

module "example-team-read-replica" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=5.6"

  cluster_name         = var.cluster_name
  cluster_state_bucket = var.cluster_state_bucket

  application            = var.application
  environment-name       = var.environment-name
  is-production          = var.is-production
  infrastructure-support = var.infrastructure-support
  team_name              = var.team_name

  # If any other inputs of the RDS is passed in the source db which are different from defaults, 
  # add them to the replica


  # It is mandatory to set the below values to create read replica instance

  # Set the database_name of the source db
  db_name = module.example_team_rds.database_name

  # Set the db_identifier of the source db 
  replicate_source_db         = module.example_team_rds.db_identifier

  # Set to true. No backups or snapshots are created for read replica
  skip_final_snapshot         = "true"
  db_backup_retention_period  = 0

  providers = {
    # Can be either "aws.london" or "aws.ireland"
    aws = aws.london
  }

  # If db_parameter is specified in source rds instance, use the same values. 
  # If not specified you dont need to add any. It will use the default values.

  # db_parameter = [
  #   {
  #     name         = "rds.force_ssl"
  #     value        = "0"
  #     apply_method = "immediate"
  #   }
  # ]
}

resource "kubernetes_secret" "example_team_rds" {
  metadata {
    name      = "example-team-rds-instance-output"
    namespace = "my-namespace"
  }

  data = {
    rds_instance_endpoint = module.example_team_rds.rds_instance_endpoint
    database_name         = module.example_team_rds.database_name
    database_username     = module.example_team_rds.database_username
    database_password     = module.example_team_rds.database_password
    rds_instance_address  = module.example_team_rds.rds_instance_address
    access_key_id         = module.example_team_rds.access_key_id
    secret_access_key     = module.example_team_rds.secret_access_key
  }
  /* You can replace all of the above with the following, if you prefer to
     * use a single database URL value in your application code:
     *
     * url = "postgres://${module.example_team_rds.database_username}:${module.example_team_rds.database_password}@${module.example_team_rds.rds_instance_endpoint}/${module.example_team_rds.database_name}"
     *
     */
}

