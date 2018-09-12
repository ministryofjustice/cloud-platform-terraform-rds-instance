output "rds_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = "${aws_db_instance.rds.endpoint}"
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
