provider "aws" {
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
}

resource "aws_security_group" "custom_security_group" {
  name        = "custom-security-group"
  description = "Allow inbound traffic on port 5000 and port 22"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# this should not exist but just adding this to save cost of NAT gateway.
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# this should not exist but just adding this to save cost of NAT gateway.
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}


# resource "aws_launch_configuration" "private_launch_config_1a" {
#   name          = "private-launch-config-1a"
#   image_id      = aws_instance.private_instance_1a.ami
#   instance_type = "t2.micro"
#   user_data     = aws_instance.private_instance_1a.user_data

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_launch_configuration" "private_launch_config_1b" {
#   name          = "private-launch-config-1b"
#   image_id      = aws_instance.private_instance_1b.ami
#   instance_type = "t2.micro"
#   user_data     = aws_instance.private_instance_1b.user_data

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "private_autoscaling_group_1a" {
#   name                      = "private-asg-1a"
#   launch_configuration      = aws_launch_configuration.private_launch_config_1a.name
#   vpc_zone_identifier       = [aws_subnet.private_subnet_1.id]
#   min_size                  = 1
#   max_size                  = 4
#   desired_capacity          = 2
#   health_check_type         = "EC2"
#   health_check_grace_period = 300
#   termination_policies      = ["OldestInstance"]

#   tag {
#     key                 = "Name"
#     value               = "private-instance"
#     propagate_at_launch = true
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "private_autoscaling_group_1b" {
#   name                      = "private-asg-1b"
#   launch_configuration      = aws_launch_configuration.private_launch_config_1b.name
#   vpc_zone_identifier       = [aws_subnet.private_subnet_2.id]
#   min_size                  = 1
#   max_size                  = 4
#   desired_capacity          = 2
#   health_check_type         = "EC2"
#   health_check_grace_period = 300
#   termination_policies      = ["OldestInstance"]

#   tag {
#     key                 = "Name"
#     value               = "private-instance"
#     propagate_at_launch = true
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }
