#######################################
# ALB + target group + listener
#######################################
resource "aws_lb" "alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]

  # Two AZs
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]

  tags = { Name = "demo-alb" }
}

resource "aws_lb_target_group" "tg" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

###################################
# Launch template & Auto-Scaling
###################################
data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix            = "nginx-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]

  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    yum -y install nginx
    systemctl enable nginx --now
  USERDATA
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "nginx-asg" }
  }
}

resource "aws_autoscaling_group" "asg" {
  name             = "nginx-asg"
  max_size         = 3
  min_size         = 1
  desired_capacity = 2

  # Private subnets in both AZs
  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.tg.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "nginx-asg"
    propagate_at_launch = true
  }
}

