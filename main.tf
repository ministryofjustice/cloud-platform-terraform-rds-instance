data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name == "live" ? "live-1" : var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "Private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier             = "cloud-platform-${random_id.id.hex}"
  db_name                = var.db_name != "" ? var.db_name : "db${random_id.id.hex}"
  db_arn                 = aws_db_instance.rds.arn
  db_pg_arn              = aws_db_parameter_group.custom_parameters.arn
  vpc_security_group_ids = concat([aws_security_group.rds-sg.id], var.vpc_security_group_ids)
  tag_for_auto_shutdown  = var.enable_rds_auto_start_stop ? { "cloud-platform-rds-auto-shutdown" = "Schedule RDS Stop/Start during non-business hours for cost saving" } : null
  default_tags = {
    business-unit          = var.business_unit
    application            = var.application
    is-production          = var.is_production
    environment-name       = var.environment_name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
    namespace              = var.namespace
  }
  db_password_rotation_seed = var.db_password_rotated_date == "" ? {} : { "db-password-rotated-date" = var.db_password_rotated_date }
}

resource "random_string" "username" {
  length  = 8
  special = false
}

resource "random_password" "password" {
  length  = 16
  special = false
  keepers = local.db_password_rotation_seed
}

resource "aws_kms_key" "kms" {
  count       = var.replicate_source_db != null ? 0 : 1
  description = local.identifier

  tags = local.default_tags
}

resource "aws_kms_alias" "alias" {
  count         = var.replicate_source_db != null ? 0 : 1
  name          = "alias/${local.identifier}"
  target_key_id = aws_kms_key.kms[0].key_id
}

resource "aws_db_subnet_group" "db_subnet" {
  count      = var.replicate_source_db != null ? 0 : 1
  name       = local.identifier
  subnet_ids = data.aws_subnets.private.ids

  tags = local.default_tags
}

resource "aws_security_group" "rds-sg" {
  name        = local.identifier
  description = "Allow all inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  # We cannot use `${aws_db_instance.rds.port}` here because it creates a
  # cyclic dependency. Rather than resorting to `aws_security_group_rule` which
  # is not ideal for managing rules, we will simply allow traffic to all ports.
  # This does not compromise security as the instance only listens on one port.
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  }
}

resource "aws_db_instance" "rds" {
  identifier                   = var.rds_name != "" ? var.rds_name : local.identifier
  final_snapshot_identifier    = var.replicate_source_db != null ? null : "${local.identifier}-finalsnapshot"
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = var.db_max_allocated_storage
  apply_immediately            = true
  engine                       = var.replicate_source_db == null ? var.db_engine : null
  engine_version               = var.replicate_source_db == null ? var.db_engine_version : null
  instance_class               = var.db_instance_class
  db_name                      = can(regex("sqlserver", var.db_engine)) ? null : local.db_name
  username                     = var.replicate_source_db != null ? null : sensitive("cp${random_string.username.result}")
  password                     = var.replicate_source_db != null ? null : random_password.password.result
  backup_retention_period      = var.db_backup_retention_period
  storage_type                 = var.db_iops == 0 ? "gp2" : "io1"
  iops                         = var.db_iops
  storage_encrypted            = can(regex("sqlserver-ex", var.db_engine)) ? false : true
  db_subnet_group_name         = var.replicate_source_db != null ? null : aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids       = local.vpc_security_group_ids
  kms_key_id                   = (var.replicate_source_db != null) || (can(regex("sqlserver-ex", var.db_engine))) ? null : aws_kms_key.kms[0].arn
  multi_az                     = can(regex("sqlserver-web|sqlserver-ex", var.db_engine)) ? false : true
  copy_tags_to_snapshot        = true
  snapshot_identifier          = var.snapshot_identifier
  replicate_source_db          = var.replicate_source_db
  auto_minor_version_upgrade   = var.allow_minor_version_upgrade
  allow_major_version_upgrade  = (var.prepare_for_major_upgrade) ? true : var.allow_major_version_upgrade
  parameter_group_name         = (var.prepare_for_major_upgrade) ? "default.${var.rds_family}" : aws_db_parameter_group.custom_parameters.name
  ca_cert_identifier           = var.replicate_source_db != null ? null : var.ca_cert_identifier
  performance_insights_enabled = var.performance_insights_enabled
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection
  backup_window                = var.backup_window
  maintenance_window           = var.maintenance_window
  license_model                = var.license_model
  character_set_name           = can(regex("sqlserver", var.db_engine)) ? var.character_set_name : null
  option_group_name            = var.option_group_name

  timeouts {
    create = "2h"
    update = "2h"
    delete = "2h"
  }

  tags = merge(local.default_tags, local.tag_for_auto_shutdown)
}

resource "aws_db_parameter_group" "custom_parameters" {
  name   = (var.prepare_for_major_upgrade) ? "${local.identifier}-upgrade" : local.identifier
  family = var.rds_family

  dynamic "parameter" {
    for_each = var.db_parameter
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Legacy long-lived credentials
resource "aws_iam_user" "user" {
  count = var.replicate_source_db != null ? 0 : 1
  name  = "rds-snapshots-user-${random_id.id.hex}"
  path  = "/system/rds-snapshots-user/"
}

resource "aws_iam_access_key" "user" {
  count = var.replicate_source_db != null ? 0 : 1
  user  = aws_iam_user.user[0].name
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "rds:CopyDBSnapshot",
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot",
      "rds:DescribeDBEngineVersions",
      "rds:DescribeDBInstances",
      "rds:DescribeDBLogFiles",
      "rds:DescribeDBSnapshotAttributes",
      "rds:DescribeDBSnapshots",
      "rds:DescribeOrderableDBInstanceOptions",
      "rds:DownloadDBLogFilePortion",
      "rds:ModifyDBInstance",
      "rds:ModifyDBSnapshot",
      "rds:ModifyDBSnapshotAttribute",
      "rds:RestoreDBInstanceFromDBSnapshot",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
    ]

    resources = [
      local.db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
      local.db_pg_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:pg:default.*"
    ]
  }

  statement {
    actions = [
      "pi:*",
    ]

    resources = [
      "arn:aws:pi:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:metrics/rds/*",
    ]
  }
}

resource "aws_iam_user_policy" "policy" {
  count  = var.replicate_source_db != null ? 0 : 1
  name   = "rds-snapshots-read-write"
  policy = data.aws_iam_policy_document.policy.json
  user   = aws_iam_user.user[0].name
}

# Short-lived credentials (IRSA)
data "aws_iam_policy_document" "irsa" {
  version = "2012-10-17"

  statement {
    actions = [
      "rds:CopyDBSnapshot",
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot",
      "rds:DescribeDBEngineVersions",
      "rds:DescribeDBInstances",
      "rds:DescribeDBLogFiles",
      "rds:DescribeDBSnapshotAttributes",
      "rds:DescribeDBSnapshots",
      "rds:DescribeOrderableDBInstanceOptions",
      "rds:DownloadDBLogFilePortion",
      "rds:ModifyDBInstance",
      "rds:ModifyDBSnapshot",
      "rds:ModifyDBSnapshotAttribute",
      "rds:RestoreDBInstanceFromDBSnapshot",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
    ]

    resources = [
      local.db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
      local.db_pg_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:pg:default.*"
    ]
  }

  statement {
    actions = [
      "pi:*",
    ]

    resources = [
      "arn:aws:pi:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:metrics/rds/*",
    ]
  }
}

resource "aws_iam_policy" "irsa" {
  name   = "cloud-platform-rds-instance-${random_id.id.hex}"
  path   = "/cloud-platform/rds-instance/"
  policy = data.aws_iam_policy_document.irsa.json
  tags   = local.default_tags
}
