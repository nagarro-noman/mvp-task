resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2S3Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "EC2S3Policy"
  description = "Allows EC2 instances to write to S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::nagp-task-bucket-3163353/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

resource "aws_iam_instance_profile" "ec2_s3_role_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_role_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_instance" "private_instance_1a" {
  subnet_id                   = aws_subnet.private_subnet_1.id
  instance_type               = "t2.micro"
  ami                         = "ami-08e5424edfe926b43"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.custom_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_role_profile.name

  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y git python3-pip
    cd /home/ubuntu
    git clone https://github.com/nomannagarro/mvp-task.git
    cd mvp-task/web-app
    pip install -r requirements.txt
    python3 create_table.py
    nohup python3 app.py &
  EOF

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    key   = "Name"
    value = "private-instance-subnet-1a"
  }
}

resource "aws_instance" "private_instance_1b" {
  subnet_id                   = aws_subnet.private_subnet_2.id
  instance_type               = "t2.micro"
  ami                         = "ami-08e5424edfe926b43"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.custom_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_s3_role_profile.name

  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y git python3-pip
    cd /home/ubuntu
    git clone https://github.com/nomannagarro/mvp-task.git
    cd mvp-task/web-app
    pip install -r requirements.txt
    nohup python3 app.py &
  EOF

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    key   = "Name"
    value = "private-instance-subnet-1b"
  }
}
