variable "cluster_name" {
  description = "The name of the cluster (eg.: cloud-platform-live-0)"
}

variable "team_name" {}

variable "application" {}

variable "environment-name" {}

variable "is-production" {
  default = "false"
}

variable "namespace" {
  default = ""
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = ""
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "rds_name" {
  description = "Optional name of the RDS cluster. Changing the name will re-create the RDS"
  default     = ""
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console."
  default     = ""
}

variable "db_allocated_storage" {
  description = "The allocated storage in gibibytes"
  default     = "10"
}

variable "db_max_allocated_storage" {
  description = "Maximum storage limit for storage autoscaling"
  default     = "10000"
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

variable "allow_minor_version_upgrade" {
  description = "Indicates that minor version upgrades are allowed."
  default     = "true"
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed."
  default     = "false"
}

variable "rds_family" {
  description = "Maps the postgres version with the rds family, a family often covers several versions"
  default     = "postgres10"
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

variable "db_parameter" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default = [
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "immediate"
    }
  ]
  description = "A list of DB parameters to apply. Note that parameters may differ from a DB family to another"
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate."
  type        = string
  default     = ""
}

variable "skip_final_snapshot" {
  type        = string
  description = "if false(default), a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier. If true no DBSnapshot is created"
  default     = "false"
}

variable "backup_window" {
  type        = string
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: 09:46-10:16"
  default     = ""
}
variable "deletion_protection" {
  type        = string
  description = "(Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  default     = "false"
}
