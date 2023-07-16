resource "aws_lb" "application_load_balancer" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.custom_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "MyALB"
  }
}

resource "aws_lb_target_group" "upload_target_group" {
  name     = "upload-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "result_target_group" {
  name     = "result-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "upload_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.upload_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "upload_listener_rule" {
  listener_arn = aws_lb_listener.upload_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.upload_target_group.arn
  }

  condition {
    path_pattern{
      values = ["/upload*"]
    }
  }
}

resource "aws_lb_listener" "result_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.result_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "result_listener_rule" {
  listener_arn = aws_lb_listener.result_listener.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.result_target_group.arn
  }

  condition {
    path_pattern{
      values = ["/result*"]
    }
  }
}

resource "aws_autoscaling_group" "result_autoscaling_group" {
  name                 = "result-autoscaling-group"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  launch_configuration = aws_launch_configuration.result_launch_configuration.name

  target_group_arns = [aws_lb_target_group.result_target_group.arn]
}

resource "aws_autoscaling_group" "upload_autoscaling_group" {
  name                 = "upload-autoscaling-group"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  launch_configuration = aws_launch_configuration.upload_launch_configuration.name

  target_group_arns = [aws_lb_target_group.upload_target_group.arn]
}

resource "aws_launch_configuration" "result_launch_configuration" {
  name                        = "my-launch-configuration-result"
  image_id                    = "ami-08e5424edfe926b43"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.custom_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_role_profile.name
  user_data                   = <<-EOF
    #!/bin/bash
    apt update
    apt install -y git python3-pip
    cd /home/ubuntu
    git clone https://github.com/nomannagarro/mvp-task.git
    cd mvp-task/web-app
    pip install -r requirements.txt
    nohup python3 app_result.py &
    echo " Going to sleep to let db created"
    sleep 300
    python3 create_table.py
  EOF
}


resource "aws_launch_configuration" "upload_launch_configuration" {
  name                        = "my-launch-configuration-upload"
  image_id                    = "ami-08e5424edfe926b43"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.custom_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_role_profile.name
  user_data                   = <<-EOF
    #!/bin/bash
    apt update
    apt install -y git python3-pip
    cd /home/ubuntu
    git clone https://github.com/nomannagarro/mvp-task.git
    cd mvp-task/web-app
    pip install -r requirements.txt
    nohup python3 app_upload.py &
  EOF
}
