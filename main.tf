data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  name          = "alias/${local.identifier}"
  target_key_id = "${aws_kms_key.kms.key_id}"
}

resource "aws_db_subnet_group" "db_subnet" {
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
  identifier                  = "${local.identifier}"
  final_snapshot_identifier   = "${local.identifier}-finalsnapshot"
  allocated_storage           = "${var.db_allocated_storage}"
  apply_immediately           = true
  engine                      = "${var.db_engine}"
  engine_version              = "${var.db_engine_version}"
  instance_class              = "${var.db_instance_class}"
  name                        = "${local.db_name}"
  username                    = "cp${random_string.username.result}"
  password                    = "${random_string.password.result}"
  backup_retention_period     = "${var.db_backup_retention_period}"
  storage_type                = "${var.db_iops == 0 ? "gp2" : "io1" }"
  iops                        = "${var.db_iops}"
  storage_encrypted           = true
  db_subnet_group_name        = "${aws_db_subnet_group.db_subnet.name}"
  vpc_security_group_ids      = ["${aws_security_group.rds-sg.id }"]
  kms_key_id                  = "${aws_kms_key.kms.arn}"
  multi_az                    = true
  copy_tags_to_snapshot       = true
  snapshot_identifier         = "${var.snapshot_identifier}"
  allow_major_version_upgrade = "${var.allow_major_version_upgrade}"
  parameter_group_name        = "${aws_db_parameter_group.custom_parameters.name}"

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "aws_db_parameter_group" "custom_parameters" {
  name   = "${local.identifier}"
  family = "${var.rds_family}"

  parameter {
    name         = "rds.force_ssl"
    value        = "${var.force_ssl ? 1 : 0}"
    apply_method = "${var.apply_method}"
  }
}

resource "aws_iam_user" "user" {
  name = "rds-snapshots-user-${random_id.id.hex}"
  path = "/system/rds-snapshots-user/${var.team_name}/"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "rds:DescribeDBSnapshots",
      "rds:CopyDBSnapshot",
      "rds:DeleteDBSnapshot",
      "rds:DescribeDBSnapshotAttributes",
      "rds:ModifyDBSnapshot",
      "rds:CreateDBSnapshot",
      "rds:RestoreDBInstanceFromDBSnapshot",
      "rds:ModifyDBSnapshotAttribute",
    ]

    resources = [
      "${aws_db_instance.rds.arn}",
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
    ]
  }
}

resource "aws_iam_user_policy" "policy" {
  name   = "rds-snapshots-read-write"
  policy = "${data.aws_iam_policy_document.policy.json}"
  user   = "${aws_iam_user.user.name}"
}