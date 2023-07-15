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

resource "aws_lb_target_group" "target_group" {
  name     = "my-target-group"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "my-autoscaling-group"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  launch_configuration = aws_launch_configuration.launch_configuration.name

  target_group_arns = [aws_lb_target_group.target_group.arn]
}

resource "aws_launch_configuration" "launch_configuration" {
  name                        = "my-launch-configuration"
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
    echo " Going to sleep to let db created"
    sleep 300
    python3 create_table.py
    nohup python3 app.py &
  EOF
}
