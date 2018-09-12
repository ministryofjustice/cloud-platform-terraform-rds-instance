output "rds_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = "${module.example_team_rds.rds_instance_endpoint}"
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
