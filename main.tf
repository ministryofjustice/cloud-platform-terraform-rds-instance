locals {
  # Generic configuration
  identifier                = "cloud-platform-${random_id.id.hex}"
  db_name                   = var.db_name != "" ? var.db_name : "db${random_id.id.hex}"
  db_arn                    = aws_db_instance.rds.arn
  db_pg_arn                 = aws_db_parameter_group.custom_parameters.arn
  vpc_security_group_ids    = concat([aws_security_group.rds-sg.id], var.vpc_security_group_ids)
  tag_for_auto_shutdown     = var.enable_rds_auto_start_stop ? { "cloud-platform-rds-auto-shutdown" = "Schedule RDS Stop/Start during non-business hours for cost saving" } : null
  db_password_rotation_seed = var.db_password_rotated_date == "" ? {} : { "db-password-rotated-date" = var.db_password_rotated_date }
  vpc_name                  = (var.vpc_name == "live") ? "live-1" : var.vpc_name

  # engine-to-export log configuration mappings
  db_log_export_mappings = {
    postgres      = ["postgresql", "upgrade"]
    mysql         = ["audit", "error", "general", "slowquery"]
    mariadb       = ["audit", "error", "general", "slowquery"]
    sqlserver-ee  = ["agent", "error"]
    sqlserver-se  = ["agent", "error"]
    sqlserver-ex  = ["agent", "error"]
    sqlserver-web = ["agent", "error"]
    oracle-se2    = ["alert", "audit", "listener", "trace", "oemagent"]
  }

  # Retrieve logs from user-selected engine
  log_exports = var.opt_in_xsiam_logging ? lookup(local.db_log_export_mappings, var.db_engine, []) : []

  required_logging_parameters = var.opt_in_xsiam_logging && contains(["mysql", "mariadb"], var.db_engine) ? [
    {
      name         = "general_log"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = var.db_engine == "mysql" ? "slow_query_log" : "log_slow_query"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "log_output"
      value        = "FILE"
      apply_method = "immediate"
    }
  ] : []

  all_db_parameters = concat(
    local.required_logging_parameters,
    var.db_parameter
  )

  # Tags
  default_tags = {
    # Mandatory
    business-unit = var.business_unit
    application   = var.application
    is-production = var.is_production
    owner         = var.team_name
    namespace     = var.namespace # for billing and identification purposes

    # Optional
    environment-name       = var.environment_name
    infrastructure-support = var.infrastructure_support
  }
}

##################
# Get AWS region #
##################
data "aws_region" "current" {}

###########################
# Get account information #
###########################
data "aws_caller_identity" "current" {}

#######################
# Get VPC information #
#######################
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    SubnetType = "EKS-Private"
  }
}

data "aws_subnet" "eks_private" {
  for_each = toset(data.aws_subnets.eks_private.ids)
  id       = each.value
}

########################
# Generate identifiers #
########################
resource "random_id" "id" {
  byte_length = 8
}

##############################
# Generate database username #
##############################
resource "random_string" "username" {
  length  = 8
  special = false
}

##############################
# Generate database password #
##############################
resource "random_password" "password" {
  length  = 16
  special = false
  keepers = local.db_password_rotation_seed
}

#########################
# Create encryption key #
#########################
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

########################
# Create subnet groups #
########################
resource "aws_db_subnet_group" "db_subnet" {
  count      = var.replicate_source_db != null ? 0 : 1
  name       = local.identifier
  subnet_ids = data.aws_subnets.private.ids

  tags = local.default_tags
}

##########################
# Create security groups #
##########################
resource "aws_security_group" "rds-sg" {
  name        = local.identifier
  description = "Allow all inbound traffic"
  vpc_id      = data.aws_vpc.this.id

  # We cannot use `${aws_db_instance.rds.port}` here because it creates a
  # cyclic dependency. Rather than resorting to `aws_security_group_rule` which
  # is not ideal for managing rules, we will simply allow traffic to all ports.
  # This does not compromise security as the instance only listens on one port.
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = concat(
      [for s in data.aws_subnet.private : s.cidr_block],
      [for s in data.aws_subnet.eks_private : s.cidr_block]
    )
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = concat(
      [for s in data.aws_subnet.private : s.cidr_block],
      [for s in data.aws_subnet.eks_private : s.cidr_block]
    )
  }
}

###################
# Create database #
###################
resource "aws_db_instance" "rds" {
  identifier                      = var.rds_name != "" ? var.rds_name : local.identifier
  final_snapshot_identifier       = var.replicate_source_db != null ? null : "${local.identifier}-finalsnapshot"
  allocated_storage               = var.db_allocated_storage
  max_allocated_storage           = var.db_max_allocated_storage
  apply_immediately               = true
  engine                          = var.replicate_source_db == null ? var.db_engine : null
  engine_version                  = var.db_engine_version
  instance_class                  = var.db_instance_class
  db_name                         = var.replicate_source_db != null || can(regex("sqlserver", var.db_engine)) ? null : local.db_name
  username                        = var.is_migration || var.replicate_source_db != null ? null : sensitive("cp${random_string.username.result}")
  password                        = var.replicate_source_db != null ? null : random_password.password.result
  backup_retention_period         = var.db_backup_retention_period
  storage_type                    = var.storage_type
  iops                            = var.db_iops
  storage_encrypted               = can(regex("sqlserver-ex", var.db_engine)) ? false : true
  db_subnet_group_name            = var.replicate_source_db != null ? null : aws_db_subnet_group.db_subnet[0].name
  vpc_security_group_ids          = local.vpc_security_group_ids
  kms_key_id                      = (var.replicate_source_db != null) || (can(regex("sqlserver-ex", var.db_engine))) ? null : aws_kms_key.kms[0].arn
  multi_az                        = can(regex("sqlserver-web|sqlserver-ex", var.db_engine)) ? false : true
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = local.log_exports

  # if is_migration = true, use the migration_snapshop copy of the snapshot_identifier with the module's kms key
  snapshot_identifier = var.is_migration ? aws_db_snapshot_copy.rds_migration_snapshot[0].target_db_snapshot_identifier : var.snapshot_identifier

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

  lifecycle {
    precondition {
      condition = !(
        contains(["mysql", "mariadb"], var.db_engine) &&
        var.opt_in_xsiam_logging &&
        (var.option_group_name == null || var.option_group_name == "")
      )
      error_message = "For MySQL or MariaDB with opt_in_xsiam_logging enabled, you must provide a non-empty option_group_name (with the audit plugin option set)."
    }

    precondition {
      condition = var.storage_type != "io2" || (
        contains(["sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"], var.db_engine) ? var.db_allocated_storage >= 20 : var.db_allocated_storage >= 100
      )
      error_message = "When 'storage_type' is 'io2', 'db_allocated_storage' must be at least 100 GiB unless using SQL which must be at least 20 GiB."
    }

    precondition {
      condition     = var.storage_type != "io2" || (var.db_iops != null ? var.db_iops >= 1000 : false)
      error_message = "When 'storage_type' is 'io2', 'db_iops' must be specified and at least 1000."
    }

    precondition {
      condition     = var.storage_type != "gp3" || var.db_allocated_storage >= 20
      error_message = "When 'storage_type' is 'gp3', 'db_allocated_storage' must be at least 20 GiB."
    }

    precondition {
      condition = var.storage_type != "gp3" || contains(["sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"], var.db_engine) || (
        contains(["oracle-ee", "oracle-se", "oracle-se1", "oracle-se2"], var.db_engine) ? (
          var.db_allocated_storage < 200 || (var.db_iops != null ? var.db_iops >= 12000 : false)
          ) : (
          var.db_allocated_storage < 400 || (var.db_iops != null ? var.db_iops >= 12000 : false)
        )
      )
      error_message = <<EOF
        When 'storage_type' is 'gp3':
        - For Oracle engines, if 'db_allocated_storage' is at least 200 GiB, 'db_iops' must be specified and at least 12,000.
        - For other engines (excluding SQL Server), if 'db_allocated_storage' is at least 400 GiB, 'db_iops' must be specified and at least 12,000.
      EOF
    }
  }

  depends_on = [aws_cloudwatch_log_subscription_filter.rds_logs_to_firehose]
}

##########################
# Create parameter group #
##########################
resource "aws_db_parameter_group" "custom_parameters" {
  name   = (var.prepare_for_major_upgrade) ? "${local.identifier}-upgrade" : local.identifier
  family = var.rds_family

  dynamic "parameter" {
    for_each = local.all_db_parameters
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

# RDS Snapshot - if is_migration = true, create a snapshot of var.snapshot_identifier
resource "aws_db_snapshot_copy" "rds_migration_snapshot" {
  count                         = var.is_migration ? 1 : 0
  source_db_snapshot_identifier = var.snapshot_identifier
  target_db_snapshot_identifier = "${local.identifier}-migration-snapshot"
  kms_key_id                    = aws_kms_key.kms[0].arn
  tags                          = local.default_tags
}

# Short-lived credentials (IRSA)
data "aws_iam_policy_document" "irsa" {
  count   = var.enable_irsa ? 1 : 0
  version = "2012-10-17"

  statement {
    sid    = "AllowRDSAccessFor${random_id.id.hex}"
    effect = "Allow"
    actions = [
      "rds:AddTagsToResource",
      "rds:CopyDBSnapshot",
      "rds:CreateDBSnapshot",
      "rds:DeleteDBSnapshot",
      "rds:DescribeDBInstances",
      "rds:DescribeDBLogFiles",
      "rds:DescribeDBSnapshotAttributes",
      "rds:DescribeDBSnapshots",
      "rds:DownloadDBLogFilePortion",
      "rds:ModifyDBInstance",
      "rds:ModifyDBSnapshot",
      "rds:ModifyDBSnapshotAttribute",
      "rds:RestoreDBInstanceFromDBSnapshot",
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:RebootDBInstance",
    ]

    resources = [
      local.db_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:snapshot:*",
      local.db_pg_arn,
      "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:pg:default.*"
    ]
  }

  statement {
    sid    = "AllowRDSDescribeEngineOptions${random_id.id.hex}"
    effect = "Allow"
    actions = [
      "rds:DescribeDBEngineVersions",
      "rds:DescribeOrderableDBInstanceOptions",
    ]

    resources = ["*",
    ]
  }

  statement {
    sid    = "AllowPIAccessFor${random_id.id.hex}"
    effect = "Allow"
    actions = [
      "pi:*",
    ]

    resources = [
      "arn:aws:pi:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:metrics/rds/*",
    ]
  }
}

resource "aws_iam_policy" "irsa" {
  count  = var.enable_irsa ? 1 : 0
  name   = "cloud-platform-rds-instance-${random_id.id.hex}"
  path   = "/cloud-platform/rds-instance/"
  policy = data.aws_iam_policy_document.irsa[0].json
  tags   = local.default_tags
}

data "aws_iam_roles" "cloudwatch_to_firehose" {
  name_regex = "cloud-platform-cloudwatch-to-firehose20250912120805499500000001"
}

data "aws_kinesis_firehose_delivery_stream" "rds_log_stream" {
  name = "cloudwatch-export-180af1363ef3510a"
}

resource "aws_cloudwatch_log_group" "rds_cloudwatch_logs" {
  for_each          = var.opt_in_xsiam_logging ? toset(local.log_exports) : toset([])
  name              = "/aws/rds/instance/${var.rds_name != "" ? var.rds_name : local.identifier}/${each.key}"
  retention_in_days = 14
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_subscription_filter" "rds_logs_to_firehose" {
  for_each        = var.opt_in_xsiam_logging ? aws_cloudwatch_log_group.rds_cloudwatch_logs : {}
  name            = "${var.rds_name != "" ? var.rds_name : local.identifier}-${each.key}-firehose"
  log_group_name  = "/aws/rds/instance/${var.rds_name != "" ? var.rds_name : local.identifier}/${each.key}"
  filter_pattern  = ""
  destination_arn = data.aws_kinesis_firehose_delivery_stream.rds_log_stream.arn
  role_arn        = length(data.aws_iam_roles.cloudwatch_to_firehose.arns) > 0 ? tolist(data.aws_iam_roles.cloudwatch_to_firehose.arns)[0] : null
  depends_on      = [aws_cloudwatch_log_group.rds_cloudwatch_logs]
}