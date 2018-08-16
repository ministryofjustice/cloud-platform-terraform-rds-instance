output "access_key_id" {
    description = "Access key id for RDS account"
    value       = "${aws_iam_access_key.user.id}"
}

output "secret_access_key" {
    description = "Secret access key for RDS account"
    value       = "${aws_iam_access_key.user.secret}"
}

output "rds_instance_id" {
    description = "The RDS instance ID"
    value       = "${aws_db_instance.rds.endpoint}"
}
output "rds_instance_name" {
    description = "The hostname of the RDS instance"
    value       = "${aws_db_instance.rds.address}"
}

output "rds_instance_endpoint" {
    description = "The connection endpoint in address:port format"
    value       = "${aws_db_instance.rds.endpoint}"
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
output "kms_key_id" {
    description = "The ARN for the KMS encryoption key"
    value       = "${aws_db_instance.rds.kms_key_id}"
}

