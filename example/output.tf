output "access_key_id" {
    description = "Access key id for RDS account"
    value       = "${module.example_team_rds.access_key_id}"
}

output "secret_access_key" {
    description = "Secret access key for RDS account"
    value       = "${module.example_team_rds.secret_access_key}"
}
output "rds_instance_endpoint" {
    description = "The connection endpoint in address:port format"
    value       = "${module.example_team_rds.rds_instance_endpoint}"
} 

output "rds_instance_arn" {
    description = "The ARN of the RDS instance"
    value       = "${module.example_team_rds.rds_instance_arn}"
}
output "database_name" {
    description = "Name of the database"
    value       = "${module.example_team_rds.database_name}"
}

output "database_username" {
    description = "Database Username"
    value       = "${module.example_team_rds.database_username}"
}

output "database_password" {
    description = "Database Password"
    value       = "${module.example_team_rds.database_password}"
}

output "database_subnet_group_arn" {
    description = "The ARN of the db subnet group."
    value       = "${module.example_team_rds.database_subnet_group_arn}"
}
output "kms_key_arn" {
    description = "The Amazon Resource Name ARN of the key."
    value       = "${module.example_team_rds.kms_key_arn}"
}

output "kms_key_id" {
    description = "The globally unique identifier for the KMS key."
    value       = "${module.example_team_rds.kms_key_id}"
}