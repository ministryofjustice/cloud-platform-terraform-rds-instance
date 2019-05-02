# cloud-platform-terraform-rds-instance
This terraform module will create an RDS instance and all required AWS resources. A KMS key is also created in order to enable encryption.

The RDS instance that is created uses a randomly generated name to avoid any conflicts. The default database created in the instance uses the same random identifier but can be overriden by the user.

The module also deploys the instance in Multi-AZ.

The outputs of this module should allow a user to connect to the database instance.


**IMPORTANT NOTE: The latest module (4.0) does not support Live-0 deployment. Be sure to use the previous one (3.1) is you need to deploy to Live-0.**

## Usage

```hcl
module "example_team_rds" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-rds-instance"

  // The first two inputs are provided by the pipeline for cloud-platform. See the example for more detail.

  cluster_name           = "cloud-platform-live-0"
  cluster_state_bucket   = "live-0-state-bucket"
  db_allocated_storage   = "20"
  db_instance_class      = "db.t2.small"
  db_iops                = "1000"
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "exampleapp"
  is-production          = "false"
  environment-name       = "development"
  infrastructure-support = "example-team@digtal.justice.gov.uk"

  providers = {
    # This can be either "aws.london" or "aws.ireland:
    aws = "aws.london"
  }
}

```
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_name | The name of the cluster (eg.: cloud-platform-live-0) | string |  | yes |
| cluster_state_bucket | The name of the S3 bucket holding the terraform state for the cluster | string | | yes |
| db_allocated_storage | The allocated storage in gibibytes | string | `10` | no |
| db_engine | Database engine used | string | `postgres` | no |
| db_engine_version | The engine version to use | string | `10.4` | no |
| db_instance_class | The instance type of the RDS instance | string | `db.t2.small` | no |
| db_backup_retention_period | The days to retain backups. Must be 1 or greater to be a source for a Read Replica | string | `7` | yes
| db_iops | The amount of provisioned IOPS. Setting this implies a storage_type of io1 | string | `0` | ** Required if 'db_storage_type' is set to io1 ** |
| db_name | The name of the database to be created on the instance (if empty, it will be the generated random identifier) | string |  | no |
| snapshot_identifier | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console. | string | | no |
| cluster_name | The name of the cluster (eg.: cloud-platform-live-0) | string | - | yes |
| cluster_state_bucket | The name of the S3 bucket holding the terraform state for the cluster | string | - | yes |
| providers | provider (and region) creating the resources |  arrays of string | default provider | no
|

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

## Quick test for database access

Connection details exported in the Kubernetes secret can be parsed with
```
$ kubectl --context live-1 -n rds-test get secret rds-test-rds-instance-output -o json | jq -r '.data'
{
  "database_name": "...",
  "database_password": "...",
  "database_username": "...",
  "rds_instance_address": "...",
  "rds_instance_endpoint": "..."
}
```
base64decode with eg
```
$ kubectl --context live-1 -n rds-test get secret rds-test-rds-instance-output -o json | jq -r '.data[] | @base64d'
```
A Docker image containing the `psql` utility is available from [Bitnami](https://github.com/bitnami/bitnami-docker-postgresql)  (preferable to the official one because it doesn't run as root) and can be quickly launched with
```
$ kubectl --context live-1 -n rds-test run --generator=run-pod/v1 shell --rm -i --tty --image bitnami/postgresql -- bash
If you don't see a command prompt, try pressing enter.
I have no name!@shell:/$ $ psql -h cloud-platform-identifier.eu-west-2.rds.amazonaws.com -U username databasename
Password for username:
psql (10.7, server 10.6)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
db4dc779f4f67a7f18=> \l
 postgres           | cpQRXIypod | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 test_db            | cpQRXIypod | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
```

## Access outside the cluster

The databases are configured with a VPC endoint, reachable only from the cluster pods; for tasks like bulk data import `kubectl forward` can create an authenticated tunnel, with a 2-step process:

1. Create a forwarding pod, any small image that does TCP will do:
```
kubectl --context live-0 -n my-namespace run port-forward --generator=run-pod/v1 --image=djfaze/port-forward --port=5432 --env="REMOTE_HOST=cloud-platform-db-name-here.eu-west-1.rds.amazonaws.com" --env="REMOTE_PORT=5432"
```
2. Forward the DB port
```
kubectl --context live-0 -n my-namespace port-forward port-forward 5432:80
```
With this, client tools can access via localhost
```
psql -h localhost -U db-username db-name
```

## Reading Material

- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html
