provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "eu-west-2"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2            = "http://localhost:5000"
    iam            = "http://localhost:5001"
    rds            = "http://localhost:5002"
  }
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
