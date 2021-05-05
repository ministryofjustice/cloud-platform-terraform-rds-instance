provider "aws" {
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
  region     = "eu-west-2"
}

module "rds" {
  source = "../../"

  cluster_name           = "rds.cloud-platform.service.justice.gov.uk"
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  namespace              = "example-ns"
  environment-name       = "example-env"
  infrastructure-support = "example-team"
}
