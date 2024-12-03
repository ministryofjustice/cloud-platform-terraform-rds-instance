output "rds_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.rds.endpoint
}

output "rds_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.rds.address
}

output "rds_instance_port" {
  description = "The database port"
  value       = aws_db_instance.rds.port
}

output "database_name" {
  description = "Name of the database"
  value       = aws_db_instance.rds.db_name
}

output "database_username" {
  description = "Database Username"
  value       = aws_db_instance.rds.username
  sensitive   = true
}

output "database_password" {
  description = "Database Password"
  value       = aws_db_instance.rds.password
  sensitive   = true
}

output "db_identifier" {
  description = "The RDS DB Indentifer"
  value       = aws_db_instance.rds.identifier
}

output "resource_id" {
  description = "RDS Resource ID - used for performance insights (metrics)"
  value       = aws_db_instance.rds.resource_id
}

output "irsa_policy_arn" {
  description = "IAM policy ARN for access to create database snapshots"
  value       = aws_iam_policy.irsa.arn
}
