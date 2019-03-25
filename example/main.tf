terraform {
  backend "s3" {}
}

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

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=4.0"
  cluster_name           = "live-1"
  cluster_state_bucket   = "cloud-platform-terraform-state"
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "exampleapp"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "example-team@digtal.justice.gov.uk"
  aws_region             = "eu-west-2"
}

resource "kubernetes_secret" "example_team_rds" {
  metadata {
    name      = "example-team-rds-instance-output"
    namespace = "my-namespace"
  }

  data {
    rds_instance_endpoint = "${module.example_team_rds.rds_instance_endpoint}"
    database_name         = "${module.example_team_rds.database_name}"
    database_username     = "${module.example_team_rds.database_username}"
    database_password     = "${module.example_team_rds.database_password}"
    rds_instance_address  = "${module.example_team_rds.rds_instance_address}"
  }
}
