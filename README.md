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

When you create an RDS instance using this module, it is created inside a virtual private cloud (VPC), which will only accept network connections from within the kubernetes cluster.

If you need to access your database from outside the cluster (e.g. from your own development machine, or to perform a bulk data import), you can do so via the following steps:

1. Run a pod inside the cluster to forward network traffic to your RDS instance
2. Tell kubernetes to forward traffic from your local machine to the new pod
3. Access the database as if it were running on your local machine

The hostname and credentials for accessing your database will be in a kubernetes secret inside your namespace. You can retrieve them as follows:

```
kubectl get secrets -n [your namespace]

kubectl get secret [secret name] -n [your namespace] -o json

```

You will need to base64 decode the values from the secret. Here is an example assuming the secret exports a single `url` value:

```
kubectl get secret [secret name] -n [your namespace] -o json \
  | jq '.data.url' \
  | sed 's/"//g' \
  | base64 --decode
```

If you are exporting the individual database connection parameters separately (i.e. database hostname, database name, database username and database password), you will need to adapt the commands in this section accordingly. In particular, you will need to pass the parameters individually to `psql` via command-line flags.

### 1. Run a port-forward pod

There are several docker images designed to forward network traffic. We will use [marcnuri/port-forward][port-forward-image] for this example.

NB: **The cluster pod security policy (PSP) will prevent any images from running a process as the `root` user, so docker images which expect to do this will not work.**

```
kubectl \
  -n [your namespace] \
  run port-forward-pod \
  --generator=run-pod/v1 \
  --image=marcnuri/port-forward \
  --port=5432 \
  --env="REMOTE_HOST=[your database hostname]" \
  --env="LOCAL_PORT=5432" \
  --env="REMOTE_PORT=5432"
```

### 2. Forward local traffic to the port-forward-pod

```
kubectl \
  -n [your namespace] \
  port-forward \
  port-forward-pod 5432:5432
```

### 3. Access the database

```
psql [database URL from your RDS secret]
```

Please remember to delete the port-forwarding pod when you have finished.

```
kubectl delete pod port-forward-pod -n [your namespace]
```

## Reading Material

- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MariaDB.html

[port-forward-image]: https://hub.docker.com/r/marcnuri/port-forward
