data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "aws" {
  alias = "london"
  region = "eu-west-2"
}
data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket = "${var.cluster_state_bucket}"
    region = "eu-west-1"
    key    = "cloud-platform/${var.cluster_name}/terraform.tfstate"
  }
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier = "cloud-platform-${random_id.id.hex}"
  db_name    = "${var.db_name != "" ? var.db_name : "db${random_id.id.hex}"}"
}

resource "random_string" "username" {
  length  = 8
  special = false
}

resource "random_string" "password" {
  length  = 16
  special = false
}

resource "aws_kms_key" "kms" {
  provider = "aws.london"
  description = "${local.identifier}"

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "aws_kms_alias" "alias" {
  provider = "aws.london"
  name          = "alias/${local.identifier}"
  target_key_id = "${aws_kms_key.kms.key_id}"
}

resource "aws_db_subnet_group" "db_subnet" {
    provider = "aws.london"

  name       = "${local.identifier}"
  subnet_ids = ["${data.terraform_remote_state.cluster.internal_subnets_ids}"]

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "aws_security_group" "rds-sg" {
    provider = "aws.london"

  name        = "${local.identifier}"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.terraform_remote_state.cluster.vpc_id}"

  // We cannot use `${aws_db_instance.rds.port}` here because it creates a
  // cyclic dependency. Rather than resorting to `aws_security_group_rule` which
  // is not ideal for managing rules, we will simply allow traffic to all ports.
  // This does not compromise security as the instance only listens on one port.
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.cluster.internal_subnets}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.cluster.internal_subnets}"]
  }
}

resource "aws_db_instance" "rds" {
    provider = "aws.london"

  identifier                = "${local.identifier}"
  final_snapshot_identifier = "${local.identifier}-finalsnapshot"
  allocated_storage         = "${var.db_allocated_storage}"
  engine                    = "${var.db_engine}"
  engine_version            = "${var.db_engine_version}"
  instance_class            = "${var.db_instance_class}"
  name                      = "${local.db_name}"
  username                  = "cp${random_string.username.result}"
  password                  = "${random_string.password.result}"
  backup_retention_period   = "${var.db_backup_retention_period}"
  storage_type              = "${var.db_iops == 0 ? "gp2" : "io1" }"
  iops                      = "${var.db_iops}"
  storage_encrypted         = true
  db_subnet_group_name      = "${aws_db_subnet_group.db_subnet.name}"
  vpc_security_group_ids    = ["${aws_security_group.rds-sg.id }"]
  kms_key_id                = "${aws_kms_key.kms.arn}"
  multi_az                  = true
  copy_tags_to_snapshot     = true
  snapshot_identifier       = "${var.snapshot_identifier}"

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}
