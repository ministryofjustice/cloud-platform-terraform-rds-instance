#################
# Configuration #
#################
variable "vpc_name" {
  description = "The name of the vpc (eg.: cloud-platform-live-0)"
  type        = string
}

variable "rds_name" {
  description = "Optional name of the RDS cluster. Changing the name will re-create the RDS"
  default     = ""
  type        = string
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console."
  default     = ""
  type        = string
}

variable "db_allocated_storage" {
  description = "The allocated storage in gibibytes"
  default     = "20" # 20 GiG is minimum storage size for RDS PostgreSQL gp3 storage type.
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Maximum storage limit for storage autoscaling"
  default     = "10000"
  type        = string
}

variable "db_engine" {
  description = "Database engine used e.g. postgres, mysql, sqlserver-ex"
  default     = "postgres"
  type        = string

  validation {
    condition     = contains(["postgres", "mysql", "mariadb", "sqlserver-ee", "sqlserver-ex", "sqlserver-se", "sqlserver-web", "oracle-se2"], var.db_engine)
    error_message = "Choose one of Postgresql, MySQL or Microsoft SQL Server. For Aurora, see https://github.com/ministryofjustice/cloud-platform-terraform-rds-aurora."
  }
}

variable "db_engine_version" {
  description = "The engine version to use e.g. 13.2 for Postgresql, 8.0 for MySQL, 15.00.4073.23.v1 for MS-SQL. Omitting the minor release part allows for automatic updates."
  default     = "10"
  type        = string
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  default     = "db.t2.small"
  type        = string
}

variable "db_backup_retention_period" {
  description = "The days to retain backups. Must be 1 or greater to be a source for a Read Replica"
  default     = "7"
  type        = string
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), 'io1' (provisioned IOPS SSD), or 'io2' (new generation of provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not. If you specify 'io2' or 'gp3' , you must also include a value for the 'iops' parameter"
  type        = string
  default     = "gp3"
}

variable "db_iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' or `gp3`. See `notes` for limitations regarding this variable for `gp3`"
  type        = number
  default     = null # Default to null to omit 'iops' unless explicitly specified, preventing unintended changes
}

variable "db_name" {
  description = "The name of the database to be created on the instance (if empty, it will be the generated random identifier)"
  default     = ""
  type        = string
}

variable "allow_minor_version_upgrade" {
  description = "Indicates that minor version upgrades are allowed."
  default     = "true"
  type        = string
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed."
  default     = "false"
  type        = string
}

variable "rds_family" {
  description = "Maps the engine version with the parameter group family, a family often covers several versions"
  default     = "postgres10"
  type        = string
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  default     = "rds-ca-rsa2048-g1"
  type        = string
}

variable "performance_insights_enabled" {
  type        = bool
  description = "Enable performance insights for RDS? Note: the user should ensure insights are disabled once the desired outcome is achieved."
  default     = false
}

variable "enable_rds_auto_start_stop" {
  type        = bool
  description = "Enable auto start and stop of the RDS instances during 10:00 PM - 6:00 AM for cost saving"
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
  default     = null
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

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = null
}

variable "deletion_protection" {
  type        = string
  description = "(Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  default     = "false"
}

variable "license_model" {
  type        = string
  description = "License model information for this DB instance, options for MS-SQL are: license-included | bring-your-own-license | general-public-license"
  default     = null
}

variable "character_set_name" {
  type        = string
  description = "DB char set, used only by MS-SQL"
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "option_group_name" {
  type        = string
  description = "(Optional) The name of an 'aws_db_option_group' to associate to the DB instance"
  default     = null
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "(Optional) A list of additional VPC security group IDs to associate with the DB instance - in adition to the default VPC security groups granting access from the Cloud Platform"
  default     = []
}

variable "db_password_rotated_date" {
  type        = string
  default     = ""
  description = "Using this variable will spin new db password by providing date as value"
}

variable "prepare_for_major_upgrade" {
  type        = bool
  default     = false
  description = "Set this to true to change your parameter group to the default version, and to turn on the ability to upgrade major versions"
}

########
# Tags #
########
variable "business_unit" {
  description = "Area of the MOJ responsible for the service"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "is_production" {
  description = "Whether this is used for production or not"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "namespace" {
  description = "Namespace name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}
