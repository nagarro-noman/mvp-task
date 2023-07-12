resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Allow inbound connections from Lambda function"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_security_group.id]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "my-rds-instance"
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  max_allocated_storage  = 20
  db_name                = "mydatabase"
  username               = "admin"
  password               = "password"
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  tags = {
    Name = "MyRDSInstance"
  }
}
data "template_file" "rds_endpoint_template" {
  template = aws_db_instance.rds_instance.endpoint
}

resource "aws_ssm_parameter" "rds_endpoint_parameter" {
  name        = "/rds/endpoint"
  description = "RDS Endpoint URL"
  type        = "String"
  value       = data.template_file.rds_endpoint_template.rendered
}

resource "null_resource" "store_rds_endpoint" {
  provisioner "local-exec" {
    command = "aws ssm put-parameter --name /rds/endpoint --value ${aws_db_instance.rds_instance.endpoint} --type String"
  }
  depends_on = [aws_ssm_parameter.rds_endpoint_parameter]
}

