data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "random_id" "id" {
  byte_length = 16
}

resource "random_string" "identifier" {
    length = 8
    special = false
    upper = false
}

resource "random_string" "username" {
    length = 8
    special = false
}

resource "random_string" "password" {
    length = 16
    special = true
}

resource "aws_iam_user" "user" {
  name = "rds-instance-user-${random_id.id.hex}"
  path = "/system/rds-instance-user/${var.team_name}/"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

resource "aws_db_instance" "rds" {
    identifier                  = "cloud-platform-${random_string.identifier.result}"
    final_snapshot_identifier   = "${var.application}-${var.environment-name}-finalsnapshot"
    allocated_storage           = "${var.db_allocated_storage}"
    engine                      = "${var.db_engine}"
    engine_version              = "${var.db_engine_version}"
    instance_class              = "${var.db_instance_class}"
    port                        = "${var.db_port}"
    name                        = "${var.application}${var.environment-name}"
    username                    = "${random_string.username.result}"
    password                    = "${random_string.password.result}"
    backup_retention_period     = "${var.db_backup_retention_period}"
    storage_encrypted           = "${var.db_storage_encryption}"
    multi_az                    = true
    copy_tags_to_snapshot       = true






    tags {
        business-unit           = "${var.business-unit}"
        application             = "${var.application}"
        is-production           = "${var.is-production}"
        environment-name        = "${var.environment-name}"
        owner                   = "${var.team_name}"
        infrastructure-support  = "${var.infrastructure-support}"
    }
}


