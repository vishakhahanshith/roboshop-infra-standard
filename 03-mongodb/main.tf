module "mongodb_instance" {
    for_each = var.instances
    source = "terraform-aws-modules/ec2_instance/aws"
    ami = data.aws_ami.devops_ami.id
    instance_type = "t3.medium"
    vpc_security_group_ids = [data.aws_ssm_parameter.mongodb_sg_id.value]
    # It should be provisioned in Roboshop DB Subnet
    subnet_id =local.db_subnet_id
    user_data = file("mongodb.sh")
    tags = merge(
        {
            Name = "MongoDB"
        },
        var.common_tags
    )
}

module "records" {
    source = "terraform-aws-modules/route53/aws/modules/records"
    zone_name = var.zone_name
    records = [
        {
            name = "mongodb"
            type = "A"
            ttl = 1
            records = [
                module.mongodb_instance.private_ip
            ]
        }
    ]
}


