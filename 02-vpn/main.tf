module "vpn_instance" {
    for_each = var.instances
    source = "terraform-aws-modules/ec2_instance/aws"
    ami = data.aws_ami.devops_ami.id
    instance_type = "t2.micro"
    vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
    #The subnet id in the below line of code is optional, if we do not give this will be provisioned inside default subnet of default vpc
    #subnet_id = each.key == "Web" ? local.public_subnet_ids[0] : loca.private_subnet_ids[0] # This means public subnet of default vpc
    tags = merge(
        {
            Name = "Roboshop-VPN"
        },
        var.common_tags
    )
}
