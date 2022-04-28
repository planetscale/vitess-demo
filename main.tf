terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-2"

}

resource "aws_db_parameter_group" "parameter-group-gtid-mode-ON" {
   name = "parameter-group-gtid-on"
   description = "Parameter Group to turn on GTID mode"
   family = "mysql8.0"
   parameter {
     apply_method = "pending-reboot"
     name = "gtid-mode"
     value = "ON"
   }
   parameter {
        apply_method = "pending-reboot"
        name  = "enforce_gtid_consistency"
        value = "ON"
    }

    parameter {
         apply_method = "pending-reboot"
         name  = "binlog_format"
         value = "ROW"
     }

     parameter {
          name  = "max_connections"
          value = "500"
      }
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "rds-import"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.medium"

  username            = "admin"

  name                = var.db_name
  skip_final_snapshot = true

  password            = var.db_password
  publicly_accessible = true

  parameter_group_name = "${aws_db_parameter_group.parameter-group-gtid-mode-ON.id}"

  backup_retention_period = 1

  db_subnet_group_name = aws_db_subnet_group.rds.name 
  vpc_security_group_ids    = [aws_security_group.rds.id]
  apply_immediately = true
}

#resource "aws_db_instance" "example-replica" {
#  identifier_prefix   = "terraform-up-and-running"
#  replicate_source_db = aws_db_instance.example.id
#  allocated_storage   = 10
#  instance_class      = "db.t2.micro"
#  skip_final_snapshot = true
#}

resource "aws_security_group" "rds" {
  name = var.rds_security_group_name

  # Allow inbound HTTP requests
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "rds" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "rds" {
  vpc_id     = aws_vpc.rds.id
  cidr_block = "10.0.0.0/16"
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds"
  subnet_ids = [aws_subnet.rds.id]
}

