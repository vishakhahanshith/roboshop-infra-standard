module "vpn_sg" {
     source = "../../terraform-aws-security-group"
     project_name = var.project_name
     sg_name = "roboshop-vpn"
     sg_description = "allowing all ports from my home IP"
     #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
     vpc_id = data.aws_vpc.default.id
     common_tags = merge(
        var.common_tags,
        {
            Component = "VPN",
            Name = "roboshop-VPN"
        }
    )
}

module "mongodb_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "mongodb"
    sg_description = "Allowing traffic"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "MongoDB",
            Name = "MongoDB"
        }
    )
}

module "catalogue_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "catalogue"
    sg_description = "Allowing traffic"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "Catalogue",
            Name = "Catalogue"
        }
    )
}

module "web_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "web"
    sg_description = "Allowing traffic from Catalogue and User and VPN"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "Web"
        }
    )
}

module "app_alb_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "App-ALB"
    sg_description = "Allowing traffic from Catalogue and User and VPN"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "App",
            Name = "App-ALB"
        }
    )
}

module "web_alb_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "Web-ALB"
    sg_description = "Allowing traffic from Catalogue and User and VPN"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "Web",
            Name = "Web-ALB"
        }
    )
}

# Creation of redis security group in the below code
module "redis_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "redis"
    sg_description = "Allowing traffic from Catalogue and User and VPN"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "redis",
            Name = "redis"
        }
    )
}

# Creation of user security group in the below code
module "user_sg" {
    source = "../../terraform-aws-security-group"
    project_name = var.project_name
    sg_name = "user"
    sg_description = "Allowing traffic from Catalogue and User and VPN"
    #sg_ingress_rules = var.sg_ingress_rules  Always create ingress rules separately
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = merge(
        var.common_tags,
        {
            Component = "user",
            Name = "user"
        }
    )
}

resource "aws_security_group_rule" "vpn" {
     type = "ingress"
     from_port = 0
     to_port = 65535
     protocol = "tcp"
     cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
     security_group_id = module.vpn_sg.security_group_id
}

# This is allowing connections from all catalogue instances to mongodb
resource "aws_security_group_rule" "mongodb_catalogue" {
    type = "ingress"
    description = "Allowing port number 27017 from catalogue"
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    source_security_group_id = module.catalogue_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.mongodb_sg.security_group_id
}

#This is allowing traffic from VPN on port no 22 for trouble shooting
resource "aws_security_group_rule" "mongodb_vpn" {
    type = "ingress"
    description = "Allowing port number 22 from catalogue"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.mongodb_sg.security_group_id
}



resource "aws_security_group_rule" "catalogue_vpn" {
    type = "ingress"
    description = "Allowing port number 22 from VPN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.catalogue_sg.security_group_id
}

resource "aws_security_group_rule" "catalogue_app_alb" {
    type = "ingress"
    description = "Allowing port number 8080 from APP ALB"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    source_security_group_id = module.app_alb_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.catalogue_sg.security_group_id
}

resource "aws_security_group_rule" "app_alb_vpn" {
    type = "ingress"
    description = "Allowing port number 80 from VPN"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.app_alb_sg.security_group_id
}

resource "aws_security_group_rule" "app_alb_web" {
    type = "ingress"
    description = "Allowing port number 80 from web"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.web_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.app_alb_sg.security_group_id
}

resource "aws_security_group_rule" "web_vpn" {
    type = "ingress"
    description = "Allowing port number 80 from VPN"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.web_sg.security_group_id
}

resource "aws_security_group_rule" "web_web_alb" {
    type = "ingress"
    description = "Allowing port number 80 from Web ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.web_alb_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.web_sg.security_group_id
}

resource "aws_security_group_rule" "web_alb_internet" {
    type = "ingress"
    description = "Allowing port number 80 from Internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    #source_security_group_id = module.web_alb_sg.security_group_id
    cidr_blocks = ["0.0.0.0/0"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.web_alb_sg.security_group_id
}

# Enabling port no 443 from internet security group in the below code
resource "aws_security_group_rule" "web_alb_internet_https" {
    type = "ingress"
    description = "Allowing port number 443 from Internet"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    #source_security_group_id = module.web_alb_sg.security_group_id
    cidr_blocks = ["0.0.0.0/0"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.web_alb_sg.security_group_id
}

resource "aws_security_group_rule" "web_vpn_ssh" {
    type = "ingress"
    description = "Allowing port number 22 from VPN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.web_sg.security_group_id
}

resource "aws_security_group_rule" "redis_user" {
    type = "ingress"
    description = "Allowing port number 6379 from user"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    source_security_group_id = module.user_sg.security_group_id
    #cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.redis_sg.security_group_id
}

resource "aws_security_group_rule" "redis_vpn" {
    type = "ingress"
    description = "Allowing port number 22 from VPN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    #cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.redis_sg.security_group_id
}

resource "aws_security_group_rule" "user_app_alb" {
    type = "ingress"
    description = "Allowing port number 8080 from APP ALB"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    source_security_group_id = module.app_alb__sg.security_group_id
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.user_sg.security_group_id
}

resource "aws_security_group_rule" "user_vpn" {
    type = "ingress"
    description = "Allowing port number 22 from VPN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.security_group_id
    #cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.user_sg.security_group_id
}

resource "aws_security_group_rule" "mongodb_user" {
    type = "ingress"
    description = "Allowing port number 22 from VPN"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.user_sg.security_group_id
    #cidr_blocks = ["${chomp(data.http.myip.body)}/32"]#usually we give 0.0.0.0/0 which will accept connection from internet, I dont want to give it from internet
    security_group_id = module.mongodb_sg.security_group_id
}