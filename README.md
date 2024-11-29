# cloud-platform-terraform-rds-instance

[![Releases](https://img.shields.io/github/v/release/ministryofjustice/cloud-platform-terraform-rds-instance.svg)](https://github.com/ministryofjustice/cloud-platform-terraform-rds-instance/releases)

This Terraform module will create an [Amazon RDS](https://aws.amazon.com/rds/) database for use on the Cloud Platform.

## Usage

```hcl
module "rds_instance" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance?ref=version" # use the latest release

  # VPC configuration
  vpc_name = var.vpc_name

  # Database configuration
  db_engine                = "postgres"
  db_engine_version        = "15"
  rds_family               = "postgres15"
  db_instance_class        = "db.t4g.micro"
  db_max_allocated_storage = "500"

  # Tags
  business_unit          = var.business_unit
  application            = var.application
  is_production          = var.is_production
  team_name              = var.team_name
  namespace              = var.namespace
  environment_name       = var.environment
  infrastructure_support = var.infrastructure_support
}
```

### Accessing the database

#### Database Hostname/Credentials

The hostname and credentials for accessing your database will be in a
kubernetes secret inside your namespace. You can retrieve them as follows (the
`decode.rb` script is available [here][decode]):

```
$ kubectl -n [your namespace] get secret [secret name] -o yaml | ./decode.rb

---
apiVersion: v1
data:
  database_name: ...
  database_password: ...
  database_username: ...
  access_key_id: ...
  secret_access_key: ...
  rds_instance_address: cloud-platform-xxxxx.yyyyy.eu-west-2.rds.amazonaws.com
  rds_instance_endpoint: cloud-platform-xxxxx.yyyyy.eu-west-2.rds.amazonaws.com:5432
  rds_instance_port: '5432'
kind: Secret
metadata:
  creationTimestamp: '2019-05-08T16:14:23Z'
  name: secret-name
  namespace: your-namespace
  resourceVersion: '11111111'
  selfLink: "/api/v1/namespaces/your-namespace/secrets/secret-name"
  uid: 11111111-1111-1111-1111-111111111111
type: Opaque
```

If you are exporting a database URL from your RDS kubernetes secret, it might have a value like this:

```
postgres://username:password@database_id.random_id.eu-west-2.rds.amazonaws.com:5432/dbdf3589e0e7acba37

```

The database hostname is part between `@` and `:` In the example above, the database hostname is:

```
database_id.random_id.eu-west-2.rds.amazonaws.com
```

>NB: You should *always* get the database credentials from this kubernetes secret. Do not be tempted to copy the into another location (such as a ConfigMap). This is because the value of the secret can be updated when this module is updated. As long as you always get your database credentials from the kubernetes secret created by terraform, this is fine. But if you copy the value elsewhere, it will not be automatically updated in the new location, and your application will no longer be able to connect to your database.

### Launching psql in the cluster

A Docker image containing the `psql` utility is available from [Bitnami] (you
cannot use the official postgres image, because it runs as root) and can be
launched like this:

```
$ kubectl -n [your namespace] run --generator=run-pod/v1 shell --rm -i --tty --image bitnami/postgresql -- bash

If you don't see a command prompt, try pressing enter.
postgres@shell:/$
```

You can then connect to your database like this

```
postgres@shell:/$ psql -h [rds_instance_address] -U [database_username] [database_name]
Password for username: [...enter database_password here...]
psql (10.7, server 10.6)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
[database_name]=>
```

### Accessing your RDS database from your laptop

Instructions on how to do this are available [here](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/rds-external-access.html#accessing-your-rds-database)

### Managing RDS snapshots - backups and restores

An IAM user account is created which allows management of RDS snapshots - allowing snapshot create, delete, copy, restore.

Example usage via AWS CLI:

List snapshots
```
aws rds describe-db-snapshots --db-instance-identifier [db-instance-name]
```

Create snapshot
```
aws rds create-db-snapshot --db-instance-identifier [db-instance-name] --db-snapshot-identifier [your-snapshot-name]
```

See the [examples/](examples/) folder for more information.

### Upgrading your RDS or changing the instance type
Instructions on how to do this are available [here](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/relational-databases/upgrade.html#upgrading-a-database-version-or-changing-the-instance-type)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.custom_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.db_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.rds-sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.eks_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.eks_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed. | `string` | `"false"` | no |
| <a name="input_allow_minor_version_upgrade"></a> [allow\_minor\_version\_upgrade](#input\_allow\_minor\_version\_upgrade) | Indicates that minor version upgrades are allowed. | `string` | `"true"` | no |
| <a name="input_application"></a> [application](#input\_application) | Application name | `string` | n/a | yes |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: 09:46-10:16 | `string` | `""` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_ca_cert_identifier"></a> [ca\_cert\_identifier](#input\_ca\_cert\_identifier) | Specifies the identifier of the CA certificate for the DB instance | `string` | `"rds-ca-rsa2048-g1"` | no |
| <a name="input_character_set_name"></a> [character\_set\_name](#input\_character\_set\_name) | DB char set, used only by MS-SQL | `string` | `"SQL_Latin1_General_CP1_CI_AS"` | no |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | The allocated storage in gibibytes | `number` | `"20"` | no |
| <a name="input_db_backup_retention_period"></a> [db\_backup\_retention\_period](#input\_db\_backup\_retention\_period) | The days to retain backups. Must be 1 or greater to be a source for a Read Replica | `string` | `"7"` | no |
| <a name="input_db_engine"></a> [db\_engine](#input\_db\_engine) | Database engine used e.g. postgres, mysql, sqlserver-ex | `string` | `"postgres"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The engine version to use e.g. 13.2 for Postgresql, 8.0 for MySQL, 15.00.4073.23.v1 for MS-SQL. Omitting the minor release part allows for automatic updates. | `string` | `"10"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance type of the RDS instance | `string` | `"db.t2.small"` | no |
| <a name="input_db_iops"></a> [db\_iops](#input\_db\_iops) | The amount of provisioned IOPS. | `number` | `null` | no |
| <a name="input_db_max_allocated_storage"></a> [db\_max\_allocated\_storage](#input\_db\_max\_allocated\_storage) | Maximum storage limit for storage autoscaling | `string` | `"10000"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database to be created on the instance (if empty, it will be the generated random identifier) | `string` | `""` | no |
| <a name="input_db_parameter"></a> [db\_parameter](#input\_db\_parameter) | A list of DB parameters to apply. Note that parameters may differ from a DB family to another | <pre>list(object({<br/>    apply_method = string<br/>    name         = string<br/>    value        = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "apply_method": "immediate",<br/>    "name": "rds.force_ssl",<br/>    "value": "1"<br/>  }<br/>]</pre> | no |
| <a name="input_db_password_rotated_date"></a> [db\_password\_rotated\_date](#input\_db\_password\_rotated\_date) | Using this variable will spin new db password by providing date as value | `string` | `""` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | (Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false. | `string` | `"false"` | no |
| <a name="input_enable_rds_auto_start_stop"></a> [enable\_rds\_auto\_start\_stop](#input\_enable\_rds\_auto\_start\_stop) | Enable auto start and stop of the RDS instances during 10:00 PM - 6:00 AM for cost saving | `bool` | `false` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name | `string` | n/a | yes |
| <a name="input_infrastructure_support"></a> [infrastructure\_support](#input\_infrastructure\_support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_is_production"></a> [is\_production](#input\_is\_production) | Whether this is used for production or not | `string` | n/a | yes |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | License model information for this DB instance, options for MS-SQL are: license-included \| bring-your-own-license \| general-public-license | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace name | `string` | n/a | yes |
| <a name="input_option_group_name"></a> [option\_group\_name](#input\_option\_group\_name) | (Optional) The name of an 'aws\_db\_option\_group' to associate to the DB instance | `string` | `null` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable performance insights for RDS? Note: the user should ensure insights are disabled once the desired outcome is achieved. | `bool` | `false` | no |
| <a name="input_prepare_for_major_upgrade"></a> [prepare\_for\_major\_upgrade](#input\_prepare\_for\_major\_upgrade) | Set this to true to change your parameter group to the default version, and to turn on the ability to upgrade major versions | `bool` | `false` | no |
| <a name="input_rds_family"></a> [rds\_family](#input\_rds\_family) | Maps the engine version with the parameter group family, a family often covers several versions | `string` | `"postgres10"` | no |
| <a name="input_rds_name"></a> [rds\_name](#input\_rds\_name) | Optional name of the RDS cluster. Changing the name will re-create the RDS | `string` | `""` | no |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. | `string` | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | if false(default), a DB snapshot is created before the DB instance is deleted, using the value from final\_snapshot\_identifier. If true no DBSnapshot is created | `string` | `"false"` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console. | `string` | `""` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), 'io1' (provisioned IOPS SSD), or 'io2' (new generation of provisioned IOPS SSD). If you specify 'io2', you must also include a value for the 'iops' parameter and the `allocated_storage` must be at least 100 GiB (except for SQL Server which the minimum is 20 GiB). | `string` | `"gp3"` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | Team name | `string` | n/a | yes |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the vpc (eg.: cloud-platform-live-0) | `string` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | (Optional) A list of additional VPC security group IDs to associate with the DB instance - in adition to the default VPC security groups granting access from the Cloud Platform | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the database |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | Database Password |
| <a name="output_database_username"></a> [database\_username](#output\_database\_username) | Database Username |
| <a name="output_db_identifier"></a> [db\_identifier](#output\_db\_identifier) | The RDS DB Indentifer |
| <a name="output_irsa_policy_arn"></a> [irsa\_policy\_arn](#output\_irsa\_policy\_arn) | IAM policy ARN for access to create database snapshots |
| <a name="output_rds_instance_address"></a> [rds\_instance\_address](#output\_rds\_instance\_address) | The hostname of the RDS instance |
| <a name="output_rds_instance_endpoint"></a> [rds\_instance\_endpoint](#output\_rds\_instance\_endpoint) | The connection endpoint in address:port format |
| <a name="output_rds_instance_port"></a> [rds\_instance\_port](#output\_rds\_instance\_port) | The database port |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | RDS Resource ID - used for performance insights (metrics) |
<!-- END_TF_DOCS -->

## Tags

Some of the inputs for this module are tags. All infrastructure resources must be tagged to meet the MOJ Technical Guidance on [Documenting owners of infrastructure](https://technical-guidance.service.justice.gov.uk/documentation/standards/documenting-infrastructure-owners.html).

You should use your namespace variables to populate these. See the [Usage](#usage) section for more information.

## Reading Material

- [Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/#cloud-platform-user-guide)
- [Amazon RDS for MySQL user guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)
- [Amazon RDS for PostgreSQL user guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Amazon RDS for MariaDB user guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html)

[decode]: https://github.com/ministryofjustice/cloud-platform-environments/blob/main/bin/decode.rb
[Bitnami]: https://github.com/bitnami/bitnami-docker-postgresql
