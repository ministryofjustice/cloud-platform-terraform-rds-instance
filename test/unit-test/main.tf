provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "eu-west-2"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    kms = "http://localhost:4566"
    rds = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

module "vpc" {
  version = "2.78.0"
  source  = "terraform-aws-modules/vpc/aws"

  name                   = local.vpc_name
  cidr                   = "10.0.0.0/8"
  azs                    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets        = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets         = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  enable_nat_gateway     = false
  enable_vpn_gateway     = false
  create_egress_only_igw = false
  create_igw             = false
  enable_dns_hostnames   = false
  enable_ipv6            = true

  public_subnet_tags = merge({
    SubnetType               = "Utility"
    "kubernetes.io/role/elb" = "1"
  }, local.tags)

  private_subnet_tags = merge({
    SubnetType                        = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  }, local.tags)

  vpc_tags = local.tags

  tags = {
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

module "rds" {
  source     = "../../"
  depends_on = [module.vpc]

  cluster_name           = "example-cluster"
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "example-app"
  is-production          = "false"
  namespace              = "example-ns"
  environment-name       = "example-env"
  infrastructure-support = "example-team"

  db_engine         = "postgres"
  db_engine_version = "13"
}

locals {
  vpc_name             = "example-cluster"
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
  tags = {
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
  }
}

resource "kubernetes_secret" "rds" {
  metadata {
    name      = "rds-instance-output"
    namespace = "example-namespace"
  }

  data = {
    rds_instance_endpoint = module.rds.rds_instance_endpoint
    database_name         = module.rds.database_name
    database_username     = module.rds.database_username
    database_password     = module.rds.database_password
    rds_instance_address  = module.rds.rds_instance_address
    access_key_id         = module.rds.access_key_id
    secret_access_key     = module.rds.secret_access_key
  }
}
