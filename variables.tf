variable "cluster_name" {
  description = "The name of the cluster (eg.: cloud-platform-live-0)"
}

variable "cluster_state_bucket" {
  description = "The name of the S3 bucket holding the terraform state for the cluster"
}

variable "team_name" {}

variable "application" {}

variable "environment-name" {}

variable "is-production" {
  default = "false"
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "rds_name"{
  description = "Optional name of the RDS cluster. Changing the name will re-create the RDS"
  default = ""
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console."
  default     = ""
}

variable "db_allocated_storage" {
  description = "The allocated storage in gibibytes"
  default     = "10"
}

variable "db_engine" {
  description = "Database engine used e.g. postgres, mqsql"
  default     = "postgres"
}

variable "db_engine_version" {
  description = "The engine version to use e.g. 10"
  default     = "10"
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  default     = "db.t2.small"
}

variable "db_backup_retention_period" {
  description = "The days to retain backups. Must be 1 or greater to be a source for a Read Replica"
  default     = "7"
}

variable "db_iops" {
  description = "The amount of provisioned IOPS. Setting this to a value other than 0 implies a storage_type of io1"
  default     = 0
  type        = number
}

variable "db_name" {
  description = "The name of the database to be created on the instance (if empty, it will be the generated random identifier)"
  default     = ""
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed."
  default     = "false"
}

variable "force_ssl" {
  description = "Enforce SSL connections, set to true to enable"
  default     = "true"
}

variable "rds_family" {
  description = "Maps the postgres version with the rds family, a family often covers several versions"
  default     = "postgres10"
}

variable "apply_method" {
  description = "Indicates when to apply parameter updates, some engines can't apply some parameters without a reboot, so set to pending-reboot"
  default     = "immediate"
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  default     = "rds-ca-2019"
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable performance insights for RDS?"
  default     = false
}

