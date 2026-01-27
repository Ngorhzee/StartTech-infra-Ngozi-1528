data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# security groups for alb and backend
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-backend-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "${var.project_name}-backend-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "backend_repo"{
    name = "${var.project_name}-backend"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }

}

# iam role  for backend ec2 intances

resource "aws_iam_role" "backend_role" {
    name = "${var.project_name}-backend-ec2-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

}

# IAM policy for EC2 instances to pull from ECR
resource "aws_iam_role_policy" "ecr_pull_policy" {
  name = "${var.project_name}-backend-ecr-pull"
  role = aws_iam_role.backend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = "*"
    }]
  })
}

# instance profile for backend ec2 intances
resource "aws_iam_instance_profile" "backend_instance_profile" {
  name = "${var.project_name}-backend-ec2-profile"
  role = aws_iam_role.backend_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.backend_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# application load balancer for backend ec2 intances
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-backend-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/ping"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}





#launch template for backend ec2 intances
resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_instance_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.backend_sg.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    apt-get update
    apt-get install -y docker.io awscli
    systemctl start docker
    systemctl enable docker

    aws ecr get-login-password --region ${var.aws_region} | \
      docker login --username AWS --password-stdin ${aws_ecr_repository.backend_repo.repository_url}

    docker run -d \
      -p 8080:8080 \
      --restart unless-stopped \
      ${aws_ecr_repository.backend_repo.repository_url}:latest
  EOF
  )
}


# autoscaling group for backend ec2 intances
resource "aws_autoscaling_group" "backend_asg" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend_tg.arn]
}
