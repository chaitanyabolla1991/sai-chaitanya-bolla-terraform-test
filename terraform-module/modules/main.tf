provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*x86_64"]
  }
}

resource "aws_launch_template" "this" {
  name_prefix   = var.autoscaling_group_name
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }
  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y nginx amazon-cloudwatch-agent
systemctl enable nginx
systemctl start nginx
EOF
)
}

resource "aws_autoscaling_group" "this" {
  name                      = var.autoscaling_group_name
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = var.private_subnet_ids
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  health_check_type         = "EC2"
  force_delete              = true
  instance_refresh {
    strategy = "Rolling"
    triggers = ["launch_template"]
  }
}

resource "aws_iam_role" "ssm" {
  name = "${var.autoscaling_group_name}-ssm"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.autoscaling_group_name}-profile"
  role = aws_iam_role.ssm.name
}

