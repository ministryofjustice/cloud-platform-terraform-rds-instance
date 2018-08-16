variable "team_name" {
}

variable "db_allocated_storage" {
    description = "The allocated storage in gibibytes"
    default = 10
}
variable "db_engine" {
    description = "Database engine used e.g. postgres, mqsql"
    default = "postgres"
}
variable "db_engine_version" {
    description = "The engine version to use e.g. 10.4"
    default = "10.4"
}
variable "db_instance_class" {
    description = "The instance type of the RDS instance"
    default = "db.t2.small"
}

variable "db_backup_retention_period" {
    description = "The days to retain backups. Must be 1 or greater to be a source for a Read Replica"
}

variable "db_port" {
    description = "The port on which the DB accepts connections"
    default = 5432
}

variable "db_storage_encryption" {
    description = "Specifies whether the DB instance is encrypted"
    default     = true
} 

variable "business-unit" {
  description = " Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "application" {}

variable "is-production" {
  default = "false"
}

variable "environment-name" {}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}