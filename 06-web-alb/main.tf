resource "aws_lb" "web_alb" {
    name = "${var.project_name}-${var.common_tags.Component}"
    internal = false #because we are going to give this to the public
    load_balancer_type = "application"
    security_groups = [data.data.aws_ssm_parameter.web_alb_sg_id.value]
    subnets = split(",",data.aws_ssm_parameter.public_subnet_ids.value)
    tags = var.common_tags
}

# Creating certificate in the below code
resource "aws_acm_certificate" "joindevops" {
    domain_name = "joindevops.online"
    validation_method = "DNS"
    tags = var.common_tags
}

# Checking the data source in the below code
data "aws_route53_zone" "joindevops" {
    name = "joindevops.online"
    private_zone = false
}

# Below code will create the records
resource "aws_route53_record" "joindevops" {
    for_each = {
        for dvo in aws_acm_certificate.joindevops.domain_validation_options : dvo.domain_name => {
            name = dvo.resource_record_name
            record = dvo.resource_record_value
            type = dvo.resource_record_type            
        }
    }
    allow_overwrite = true
    name = each.value.name
    records = [each.value.record]
    ttl = 60
    type = each.value.type
    zone_id = data.aws_route53_zone.joindevops.zone_id
}

# Below is the validation code(That is the below code will approve the validation)
resource "aws_acm_certificate_validation" "joindevops" {
    certificate_arn = aws_acm_certificate.joindevops.arn
    validation_record_fqdns = [for record in aws_aws_route53_record.joindevops : record.fqdn]
}

resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.web_alb.arn
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"
    certificate_arn = aws_acm_certificate.joindevops.arn

    # The below code will add one listener on port no 80 and default rule
    # If someone hits on port 80, the default rule is this one
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "This is the fixed response from WEB ALB HTTPS"
        status_code = "200"
      }
    }    
}

# Creating route 53 record in the below code
module "records" {
    source = "terraform-aws-modules/route53/aws/modules/records"
    version = "~> 2.0"

    zone_name = "joindevops.online"

    records = [
        {
            name = "*.app"
            type = "A"
            alias = {
               name = aws_lb.web_alb.dns_name
               zone_id = aws_lb.web_alb.zone_id
            }
        }
    ]
}