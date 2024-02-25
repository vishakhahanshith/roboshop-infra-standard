locals {
    database_subnet_ids = element(split(",", data.aws_ssm_parameter.database_subnet_ids.value),0)
}