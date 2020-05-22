# cloud-platform-terraform-rds-instance

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-rds-instance/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-rds-instance/releases)

This terraform module will create an RDS instance and all required AWS resources. A KMS key is also created in order to enable encryption.

The RDS instance that is created uses a randomly generated name to avoid any conflicts. The default database created in the instance uses the same random identifier but can be overriden by the user.

The module also deploys the instance in Multi-AZ.

The outputs of this module should allow a user to connect to the database instance.

When upgrading the major version of an engine, `allow_major_version_upgrade` must be set to `true`, as default is set to false.

Some engines can't apply some parameters without a reboot(ex postgres9.x cant apply force_ssl immediate), and you will need to specify "pending-reboot" here.


## Usage

See [this example](example/rds.tf)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allow_major_version_upgrade | Indicates that major version upgrades are allowed |  string | false | no |
| cluster_name | The name of the cluster (eg.: cloud-platform-live-0) | string |  | yes |
| cluster_state_bucket | The name of the S3 bucket holding the terraform state for the cluster | string | | yes |
| db_allocated_storage | The allocated storage in gibibytes | string | `10` | no |
| db_engine | Database engine used | string | `postgres` | no |
| db_engine_version | The engine version to use | string | `10.4` | no |
| db_instance_class | The instance type of the RDS instance | string | `db.t2.small` | no |
| db_backup_retention_period | The days to retain backups. Must be 1 or greater to be a source for a Read Replica | string | `7` | yes
| db_iops | The amount of provisioned IOPS. Setting this implies a storage_type of io1 | string | `0` | ** Required if 'db_storage_type' is set to io1 ** |
| db_name | The name of the database to be created on the instance (if empty, it will be the generated random identifier) | string |  | no |
| force_ssl | Enforce SSL connections | boolean | `true` | no |
| performance_insights_enabled | Enable performance insights in RDS | boolean | `false` | no |
| snapshot_identifier | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console. | string | | no |
| providers | provider (and region) creating the resources |  arrays of string | default provider | no |
| rds_family | rds configuration version | string | `postgres10` | no  |
| apply_method | Indicates when to apply parameter updates | string | `immediate` | no  |
| ca_cert_identifier | Specifies the identifier of the CA certificate for the DB instance | string | `rds-ca-2019` | no  |


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

## Outputs

| Name | Description |
|------|-------------|
| rds_instance_endpoint | The connection endpoint in address:port format |
| rds_instance_address | The hostname of the RDS instance |
| rds_instance_port | The database port |
| database_name | Name of the database |
| database_username | Database Username |
| database_password | Database Password |
| access_key_id | Access key id for RDS snapshot management |
| secret_access_key | Secret key for RDS snapshot management |

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

[decode]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/bin/decode.rb
[Bitnami]: https://github.com/bitnami/bitnami-docker-postgresql
