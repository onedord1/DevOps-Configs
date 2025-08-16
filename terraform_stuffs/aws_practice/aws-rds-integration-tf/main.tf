terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.84"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "VPC"
  }
}

###  VPC Block ########
#### create IG ####

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}

#### ADD ROUTE TABLE TO IG ###


resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

### VPC BLOCK END ##########

#### RDS DB SERVER #######
resource "aws_subnet" "rds_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[0]

  tags = {
    Name = "rds_private_subnet1"
  }
}

resource "aws_subnet" "rds_subnet2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zones[3]

  tags = {
    Name = "rds_private_subnet2"
  }
}

####  CREATE SUBNET GROUP  ####

resource "aws_db_subnet_group" "rds" {
  name       = "main"
  subnet_ids = ["${aws_subnet.rds_subnet1.id}", "${aws_subnet.rds_subnet2.id}"]

  tags = {
    Name = "Portfolio_RDS_Subnet_Group"
  }
}

###### CREATE RDS SECURITY GROUP  ######

resource "aws_security_group" "rds" {
  name        = "mysqlallow"
  description = "ssh allow to the mysql"
  vpc_id      = aws_vpc.vpc.id


  ingress {
    description     = "ssh"
    security_groups = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
  }
  ingress {
    description     = "MYSQL"
    security_groups = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG Portfolio RDS"
  }
}

#### RDS DB OPTION GROUP ####

resource "aws_db_option_group" "rds" {
  name                     = "optiongroup-test-terraform"
  option_group_description = "Terraform Option Group"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT"
    }

    option_settings {
      name  = "SERVER_AUDIT_FILE_ROTATIONS"
      value = "37"
    }
  }
}

### CREATE DB PARAMETER GROUP ####

resource "aws_db_parameter_group" "rds" {
  name   = "rdsmysql"
  family = "mysql8.0"

  parameter {
    name  = "autocommit"
    value = "1"
  }

  parameter {
    name  = "binlog_error_action"
    value = "IGNORE_ERROR"
  }
}

data "local_file" "sql_script" {
  filename = "${path.module}/obbs.sql"
}


#####  CREATE RDS DB INSTANCE    ######

resource "aws_db_instance" "rds" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t2.micro"
  db_name                = var.database_name
  username               = var.database_user
  password               = var.database_password
  db_subnet_group_name   = aws_db_subnet_group.rds.id
  option_group_name      = aws_db_option_group.rds.id
  publicly_accessible    = "false"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  parameter_group_name   = aws_db_parameter_group.rds.id
  skip_final_snapshot    = true
/*
  provisioner "local-exec" {
    command = "mysql --host=${aws_db_instance.rds.endpoint} --port=${var.database_port} --user=${var.database_user} --password=${var.database_password} --database=${var.database_name} < ${data.local_file.sql_script.content}"
  }
*/
  tags = {
    Name = "RDS-MySQL"
  }
}

### WEB SERVERS #####

#### CREATE  WEB SUBNET--PUBLIC #######

resource "aws_subnet" "web_subnet2" {

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[1]

  tags = {
    Name = "public-subnet2"
  }
}

resource "aws_subnet" "web_subnet3" {

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones[2]

  tags = {
    Name = "public-subnet3"
  }
}

#CREATE  WEB SUCURITY GROUP
resource "aws_security_group" "web_sg1" {
  name        = "SG for Instance"
  description = "created by terraform"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Demo_SG1"
  }
}

#CREATE WEB SUCURITY GROUP2
resource "aws_security_group" "web_sg2" {
  name        = "SG2 for Instance"
  description = "Terraform example security group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Demo_SG2"
  }
}
####   CREATE EC2 INSTANCE  #####
resource "aws_instance" "app_server" {
  ami                                  = var.amis[var.aws_region]
  instance_type                        = "t2.micro"
  associate_public_ip_address          = true
  key_name                             = "aws-key"
  vpc_security_group_ids               = ["${aws_security_group.web_sg1.id}", "${aws_security_group.web_sg2.id}"]
  subnet_id                            = aws_subnet.web_subnet2.id
  user_data                            = templatefile("user_data.tfpl", { rds_endpoint = "${aws_db_instance.rds.endpoint}", user = var.database_user, password = var.database_password, dbname = var.database_name })
  instance_initiated_shutdown_behavior = "terminate"
  root_block_device {
    volume_type = "gp2"
    volume_size = "15"
  }

  tags = {
    Name = var.instance_name
  }

  depends_on = [aws_db_instance.rds]
}

/*
resource "null_resource" "db_setup" {
  depends_on = [aws_db_instance.rds]
  provisioner "local-exec" {
    command = "mysql --host=${aws_db_instance.rds.endpoint} --port=${var.database_port} --user=${var.database_user} --password=${var.database_password} --database=${var.database_name} < ${data.local_file.sql_script.content}"
  }
}
*/