module "rabbitmq_instance" {
    for_each = var.instances
    source = "terraform-aws-modules/ec2_instance/aws"
    ami = data.aws_ami.devops_ami.id
    instance_type = "t3.medium"
    vpc_security_group_ids = [data.aws_ssm_parameter.rabbitmq_sg_id.value]
    # It should be provisioned in Roboshop DB Subnet
    subnet_id =local.db_subnet_id
    user_data = file("mysql.sh")
    tags = merge(
        {
            Name = "rabbitmq"
        },
        var.common_tags
    )
}

module "records" {
    source = "terraform-aws-modules/route53/aws/modules/records"
    zone_name = var.zone_name
    records = [
        {
            name = "rabbitmq"
            type = "A"
            ttl = 1
            records = [
                module.rabbitmq_instance.private_ip
            ]
        }
    ]
}


