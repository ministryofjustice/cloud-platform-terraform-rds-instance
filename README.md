# cloud-platform-terraform-rds-instance

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-rds-instance/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-rds-instance/releases)

This terraform module will create an RDS instance and all required AWS resources. A KMS key is also created in order to enable encryption.

The RDS instance that is created uses a randomly generated name to avoid any conflicts. The default database created in the instance uses the same random identifier but can be overriden by the user.

The module also deploys the instance in Multi-AZ.

The outputs of this module should allow a user to connect to the database instance.

When upgrading the major version of an engine, `allow_major_version_upgrade` must be set to `true`, as default is set to false.

Some engines can't apply some parameters without a reboot(ex postgres9.x cant apply force_ssl immediate), and you will need to specify "pending-reboot" here.

By default, a random name will be generated for the RDS. The `rds_name` parameters allows to set this identifier. 
Warning: Changing this identifier will recreated the RDS.

When creating Read Replica, make sure to pass the same inputs in the replica instance. If not specified, the module will use default values which will conflict the source RDS instance.

## Usage

See [this example](example/rds.tf)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.custom_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.db_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_access_key.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_user.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.rds-sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet_ids.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed. | `string` | `"false"` | no |
| <a name="input_allow_minor_version_upgrade"></a> [allow\_minor\_version\_upgrade](#input\_allow\_minor\_version\_upgrade) | Indicates that minor version upgrades are allowed. | `string` | `"true"` | no |
| <a name="input_application"></a> [application](#input\_application) | n/a | `any` | n/a | yes |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: 09:46-10:16 | `string` | `""` | no |
| <a name="input_business-unit"></a> [business-unit](#input\_business-unit) | Area of the MOJ responsible for the service | `string` | `""` | no |
| <a name="input_ca_cert_identifier"></a> [ca\_cert\_identifier](#input\_ca\_cert\_identifier) | Specifies the identifier of the CA certificate for the DB instance | `string` | `"rds-ca-2019"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster (eg.: cloud-platform-live-0) | `any` | n/a | yes |
| <a name="input_db_allocated_storage"></a> [db\_allocated\_storage](#input\_db\_allocated\_storage) | The allocated storage in gibibytes | `string` | `"10"` | no |
| <a name="input_db_backup_retention_period"></a> [db\_backup\_retention\_period](#input\_db\_backup\_retention\_period) | The days to retain backups. Must be 1 or greater to be a source for a Read Replica | `string` | `"7"` | no |
| <a name="input_db_engine"></a> [db\_engine](#input\_db\_engine) | Database engine used e.g. postgres, mqsql | `string` | `"postgres"` | no |
| <a name="input_db_engine_version"></a> [db\_engine\_version](#input\_db\_engine\_version) | The engine version to use e.g. 10 | `string` | `"10"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | The instance type of the RDS instance | `string` | `"db.t2.small"` | no |
| <a name="input_db_iops"></a> [db\_iops](#input\_db\_iops) | The amount of provisioned IOPS. Setting this to a value other than 0 implies a storage\_type of io1 | `number` | `0` | no |
| <a name="input_db_max_allocated_storage"></a> [db\_max\_allocated\_storage](#input\_db\_max\_allocated\_storage) | Maximum storage limit for storage autoscaling | `string` | `"10000"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The name of the database to be created on the instance (if empty, it will be the generated random identifier) | `string` | `""` | no |
| <a name="input_db_parameter"></a> [db\_parameter](#input\_db\_parameter) | A list of DB parameters to apply. Note that parameters may differ from a DB family to another | <pre>list(object({<br>    apply_method = string<br>    name         = string<br>    value        = string<br>  }))</pre> | <pre>[<br>  {<br>    "apply_method": "immediate",<br>    "name": "rds.force_ssl",<br>    "value": "1"<br>  }<br>]</pre> | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | (Optional) If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false. | `string` | `"false"` | no |
| <a name="input_environment-name"></a> [environment-name](#input\_environment-name) | n/a | `any` | n/a | yes |
| <a name="input_infrastructure-support"></a> [infrastructure-support](#input\_infrastructure-support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `any` | n/a | yes |
| <a name="input_is-production"></a> [is-production](#input\_is-production) | n/a | `string` | `"false"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `""` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable performance insights for RDS? | `bool` | `false` | no |
| <a name="input_rds_family"></a> [rds\_family](#input\_rds\_family) | Maps the postgres version with the rds family, a family often covers several versions | `string` | `"postgres10"` | no |
| <a name="input_rds_name"></a> [rds\_name](#input\_rds\_name) | Optional name of the RDS cluster. Changing the name will re-create the RDS | `string` | `""` | no |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. | `string` | `""` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | if false(default), a DB snapshot is created before the DB instance is deleted, using the value from final\_snapshot\_identifier. If true no DBSnapshot is created | `string` | `"false"` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console. | `string` | `""` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key_id"></a> [access\_key\_id](#output\_access\_key\_id) | Access key id for RDS IAM user |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the database |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | Database Password |
| <a name="output_database_username"></a> [database\_username](#output\_database\_username) | Database Username |
| <a name="output_db_identifier"></a> [db\_identifier](#output\_db\_identifier) | The RDS DB Indentifer |
| <a name="output_rds_instance_address"></a> [rds\_instance\_address](#output\_rds\_instance\_address) | The hostname of the RDS instance |
| <a name="output_rds_instance_endpoint"></a> [rds\_instance\_endpoint](#output\_rds\_instance\_endpoint) | The connection endpoint in address:port format |
| <a name="output_rds_instance_port"></a> [rds\_instance\_port](#output\_rds\_instance\_port) | The database port |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | RDS Resource ID - used for performance insights (metrics) |
| <a name="output_secret_access_key"></a> [secret\_access\_key](#output\_secret\_access\_key) | Secret key for RDS IAM user |
<!-- END_TF_DOCS -->

### Tags

Some of the inputs are tags. All infrastructure resources need to be tagged according to the [MOJ techincal guidance](https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure). The tags are stored as variables that you will need to fill out as part of your module.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application |  | string | - | yes |
| business-unit | Area of the MOJ responsible for the service | string | `mojdigital` | yes |
| environment-name |  | string | - | yes |
| infrastructure-support | The team responsible for managing the infrastructure. Should be of the form team-email | string | - | yes |
| is-production |  | string | `false` | yes |
| team_name |  | string | - | yes |


## Accessing the database

### Database Hostname/Credentials

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
postgres://cpDvquXO5B:R1eDN0xEUnaH6Aqr@cloud-platform-df3589e0e7acba37.cdwm328dlye6.eu-west-2.rds.amazonaws.com:5432/dbdf3589e0e7acba37

```

The database hostname is part between `@` and `:` In the example above, the database hostname is:

```
cloud-platform-df3589e0e7acba37.cdwm328dlye6.eu-west-2.rds.amazonaws.com
```

> NB: You should *always* get the database credentials from this kubernetes secret. Do not be tempted to copy the into another location (such as a ConfigMap). This is because the value of the secret can be updated when this module is updated. As long as you always get your database credentials from the kubernetes secret created by terraform, this is fine. But if you copy the value elsewhere, it will not be automatically updated in the new location, and your application will no longer be able to connect to your database.

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

### 4. Managing RDS snapshots - backups and restores

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


## Reading Material

- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html

[decode]: https://github.com/ministryofjustice/cloud-platform-environments/blob/main/bin/decode.rb
[Bitnami]: https://github.com/bitnami/bitnami-docker-postgresql
