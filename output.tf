output "access_key_id" {
    description = "Access key id for RDS account"
    value       = "${aws_iam_access_key.user.id}"
}

output "secret_access_key" {
    description = "Secret access key for RDS account"
    value       = "${aws_iam_access_key.user.secret}"
}
output "rds_instance_endpoint" {
    description = "The connection endpoint in address:port format"
    value       = "${aws_db_instance.rds.endpoint}"
} 

output "rds_instance_id" {
    description = "The RDS instance ID."
    value       = "${aws_db_instance.rds.id}"
}

output "rds_instance_arn" {
    description = "The ARN of the RDS instance"
    value       = "${aws_db_instance.rds.arn}"
}
output "database_name" {
    description = "Name of the database"
    value       = "${aws_db_instance.rds.name}"
}

output "database_username" {
    description = "Database Username"
    value       = "${aws_db_instance.rds.username}"
}

output "database_password" {
    description = "Database Password"
    value       = "${aws_db_instance.rds.password}"
}

output "database_subnet_group_arn" {
    description = "The ARN of the db subnet group."
    value       = "${aws_db_subnet_group.db_subnet.name}"
}
output "kms_key_arn" {
    description = "The Amazon Resource Name ARN of the key."
    value       = "${aws_kms_key.kms.arn}"
}

output "kms_key_id" {
    description = "The globally unique identifier for the KMS key."
    value       = "${aws_kms_key.kms.key_id}"
}

