# example AWS RDS Instance Creation

Configuration in this directory creates an example AWS RDS Instance with a MySQL database. It also provisions a database subnet group and a KMS key for decryption.

This example outputs user name and secrets for the new credentials.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Run `terraform destroy` when you want to destroy these resources created.

