provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "eu-west-2"
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:5000"
    iam = "http://localhost:5001"
    rds = "http://localhost:5002"
    sts = "http://localhost:5003"
    kms = "http://localhost:5004"
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
}

locals {
  vpc_name             = "example-cluster"
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
  tags = {
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
  }
}

module "vpc" {
  version = "2.78.0"
  source  = "terraform-aws-modules/vpc/aws"

  name                   = local.vpc_name
  cidr                   = "172.20.0.0/16"
  azs                    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets        = ["172.20.32.0/19", "172.20.64.0/19", "172.20.96.0/19"]
  public_subnets         = ["172.20.0.0/22", "172.20.4.0/22", "172.20.8.0/22"]
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
