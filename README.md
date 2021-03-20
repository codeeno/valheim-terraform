![image info](./logo.png)

# Valheim Server Terraform

This terraform code sets up a Valheim server on AWS, based on [mbround18's valheim docker image](https://github.com/mbround18/valheim-docker). The following resources are created:

* VPC with just one public subnet
* EC2 instance
* ECS cluster and Task Definition
* EFS for storing server/saves/backups files
* (Optional) Lambdas which terminate/create the EC2 instance on a schedule

The following external modules are used:

* [ diodonfrost/terraform-aws-lambda-scheduler-stop-start](https://github.com/diodonfrost/terraform-aws-lambda-scheduler-stop-start)
* [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
* [ cloudposse/terraform-aws-ecs-container-definition](https://github.com/cloudposse/terraform-aws-ecs-container-definition)

## Setup

Clone this repository and `cd` into it:

```bash
$ git clone https://github.com/codeeno/valheim-terraform
$ cd valheim-terraform
```

Copy the `terraform.tfvars.sample` file:

```bash
$ mv terraform.tfvars.sample terraform.tfvars
```

Adjust the values in the `terraform.tfvars` to your liking. Then, apply the terraform:

```bash
$ terraform apply
```

Check the outputs for the elastic public IP address of your server.


## Inputs

The inputs which start with `server` correspond to environment variables set by the docker container. Check the [official documentation](https://github.com/mbround18/valheim-docker#environment-variables) for more info.

| Name | Type        | Default | 
|------|-------------|:---------:|
| availability\_zone | `string` | `"eu-central-1a"` |
| container\_image\_tag | `string` | `"latest"` |
| enable\_scheduled\_shutdown | `bool` | `false` |
| enable\_scheduled\_startup | `bool` | `false`|
| instance\_type | `string` | n/a |
| key\_name | `string` | `null` | null |
| server\_auto\_backup | `number` | `null` |
| server\_auto\_backup\_days\_to\_live | `number` | `null` |
| server\_auto\_backup\_on\_shutdown | `number` | `null` |
| server\_auto\_backup\_on\_update | `number` | `null` |
| server\_auto\_backup\_remove\_old | `number` | `null` |
| server\_auto\_backup\_schedule | `string` | `null` |
| server\_auto\_update | `number` | `null` |
| server\_auto\_update\_schedule | `string` | `null` |
| server\_name | `string` | n/a | yes |
| server\_password | `string` | n/a | yes |
| server\_public | `number` | `1` | yes |
| server\_tz | `string` | `"Europe/Berlin"` |
| server\_update\_on\_startup | `number` | `null` |
| server\_webhook\_url | `string` | `null` |
| server\_world | `string` | n/a | yes |
| shutdown\_schedule\_expression | `string` | `null` |
| startup\_schedule\_expression | `string` | `null` |
| subnet\_cidr | `string` | `"10.0.0.0/24"` |
| task\_cpu | `number` | n/a |
| task\_memory | `number` | n/a |
| vpc\_cidr | `string` | `"10.0.0.0/16"` |
| vpc\_subnet | `string` | `"10.0.0.0/24"` |