// load balancer locals
locals {
  http_port = 80
  https_port = 443
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

// security group for load balancer
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
  vpc_id = aws_vpc.vpc.id
}

// http inbound for port 80
resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

// https inbound for port 443
resource "aws_security_group_rule" "allow_https_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port = local.https_port
  to_port = local.https_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}

data "aws_subnet_ids" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Tier = "Public"
  }
// TerraForm is building our resources later on, 
//it's going to make sure that the subnets are
// built and then it's going to execute this EC2 subnet ID 
// source afterwards.
  depends_on = [ 
    aws_subnet.subnet_1_public,
    aws_subnet.subnet_2_public,
    aws_subnet.subnet_3_public
   ]
}

// load balancer resource
resource "aws_lb" "nomad_lb" {
  name = var.cluster_name
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.public.ids
  security_groups = [aws_security_group.alb.id]

// that bucket created and any error logs or anything 
// that we want to see from the load balancer, it's going to 
// be sort of put into that separate bucket that I have created.
  access_logs {
    bucket = "fss-service-files"
    prefix = "namd-lb"
    enabled = true
  }
}

// user data to be used for launch config
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port    
    SECRET_KEY=var.stripe_secret_key
    WEB_APP_URL=var.web_app_url 
    WEB_HOOK_SECRET=var.web_hook_secret 
  }
}

// security group for instances in asg
resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = local.all_ips
  }

  egress {
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
  }
}

// get the latest ami from aws
data "aws_ami" "nomad_ami" {
  most_recent = true
  owners = [ "self" ]

  filter {
    name = "name"
    values = [ "nomad-ec2-*" ]
  }
}

// makee policy for role to add in profile for each instance
resource "aws_iam_policy" "policy" {
  name = var.policy_name
  description = "EC2 Policy for seending logs to cloudwatch"

// copy it form policy in aws 
  policy = jsonencode({
      "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:Describe*",
        "cloudwatch:*",
        "logs:*",
        "sns:*",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:GetRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
    "Effect": "Allow",
    "Action": "iam:CreateServiceLinkedRole",
    "Resource": "arn:aws:iam::*:role/aws-service-role/events.amazonaws.com/AWSServiceRoleForCloudWatchEvents*",
    "Condition": {
        "StringLike": {
            "iam:AWSServiceName": "events.amazonaws.com"
        }
    }
   }
  ]
  })
}

// create role
resource "aws_iam_role" "role" {
  name = var.role_name

  assume_role_policy = jsonencode({
        "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
  })
}

// attach policy to role
resource "aws_iam_role_policy_attachment" "attach-policy" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

// add role to  profile for instance
resource "aws_iam_instance_profile" "nomad_log_profile" {
  name = var.log_profile_name
  role = aws_iam_role.role.name
}

// launch config resource for asg each instance
resource "aws_launch_configuration" "nomad_lc" {
  name_prefix = "nomad" # name prefix for each instance
  image_id = data.aws_ami.nomad_ami.image_id # latest ami image create
  instance_type = var.instance_type
  security_groups = [ aws_security_group.instance.id ] # security group for instance
  user_data = data.template_file.user_data.rendered # user data from template
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.nomad_log_profile.name}" # profile for role created to attach it in each instance

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ data.data.aws_ami.nomad_ami ]
}

// target group resource
// basically launch and check the health status of each ec2 instance.
resource "aws_lb_target_group" "asg" {
  name = var.cluster_name
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

// asg resource
resource "aws_autoscaling_group" "nomad_asg" {
  name = "${aws_launch_configuration.nomad_lc.name}-asg" # namee of asg
  launch_configuration = aws_launch_configuration.nomad_lc.name # name of launch configration
  vpc_zone_identifier = data.aws_subnet_ids.public.ids #  launch an auto scaling group into each subnet.

  target_group_arns = [ aws_lb_target_group.asg.arn ]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key = "name"
    value = var.cluster_name
    propagate_at_launch = true
  }
# refresh or to add more. two instances whenever we get lost or 
# whenever have get up to 50% and finally we have the lifecycle
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Required to redploy without an outage
  #create the new auto scaling before destroying the old one.
  lifecycle {
    create_before_destroy = true
  }
}

// load balancer config 
// add aws_lb_listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nomad_lb.arn
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn # validte ssl certificate for custom domain
  port = "443"
  protocol = "HTTPS"

  # by default reeturn a simple 404 page , wheen route not found
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

// load balancere listener and redirect all http to https
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nomad_lb.arn
  port = local.http_port
  protocol = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

// add listener rule https
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

// add listener rule http
resource "aws_lb_listener_rule" "asg-http" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = [ "*" ]
    }
  }
}