# Example AWS RDS Instance configuration

The configuration in this directory creates an example AWS RDS PostgreSQL Instance.

This example is designed to be used in the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository.

The output will be in a kubernetes `Secret`, which includes the values `rds_instance_endpoint`, `database_name`, `database_username` and `database_password`.

## Usage

In your namespace's path in the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository, create a directory called `resources` (if you have not created one already) and refer to the contents of [main.tf](main.tf) to define the module properties. Make sure to change placeholder values to what is appropriate and refer to the top-level README file in this repository for extra variables that you can use to further customise your resource.

**Warning** due to an API (specific to Postgres instances) limitation, the variable `db_name` must consist only of letters and underscores. Also, if not defined, a random string will be generated.

Commit your changes to a branch and raise a pull request. Once approved, you can merge and the changes will be applied. Shortly after, you should be able to access the `Secret` on kubernetes and acccess the resources. You might want to refer to the [documentation on Secrets](https://kubernetes.io/docs/concepts/configuration/secret/).
