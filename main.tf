
resource "aws_instance" "this_private" {
  ami                    = "ami-08f714c552929eda9"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    # Update system
    sudo dnf update -y

    # Install Nginx, PHP, and required packages
    sudo dnf install -y nginx php php-fpm wget unzip mysql

    # Enable and start services
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo systemctl enable php-fpm
    sudo systemctl start php-fpm

    # Download and install WordPress
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xvzf latest.tar.gz
    sudo mv wordpress/* /var/www/html/

    # Set proper permissions
    sudo chown -R nginx:nginx /var/www/html
    sudo find /var/www/html -type d -exec chmod 755 {} \;
    sudo find /var/www/html -type f -exec chmod 644 {} \;

    # Restart services to apply changes
    sudo systemctl restart php-fpm
    sudo systemctl restart nginx
  EOF

  tags = { Name = "WordPress-Private" }
}



# public instance
resource "aws_instance" "this_public" {
  ami                    = "ami-08f714c552929eda9"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
tags = { Name = "Public-Instance" }
}


# RDS subnet group 
resource "aws_db_subnet_group" "wordpress" {
  name       = "wordpress-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private2.id]
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "changeme123!"
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az = false 
  deletion_protection = false
  skip_final_snapshot = true
}

# attach EC2 to ALB target group 
resource "aws_lb_target_group_attachment" "wordpress_attach" {
  target_group_arn = aws_lb_target_group.wordpress_tg.arn
  target_id        = aws_instance.this_private.id
  port             = 80
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

# subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.104.0/24"    
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
}


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.103.0/24"    
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false
}

# ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "allow_traffic_to_alb"
  description = "Allow inbound traffic to alb"
  vpc_id      = aws_vpc.this.id

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

# WordPress SG: only ALB can talk to it
resource "aws_security_group" "wordpress_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 80
    to_port         = 80
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

# Database SG: only WordPress can talk to it
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# allow ssh from anywhere - not secure just used for demo
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 22
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
}
# establish an elastic IP for the NAT gateway
resource "aws_eip" "nat" {
  tags = { Name = "nat_eip"}
} 


# Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
}

# NAT gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.gw]
  tags = { Name = "gw NAT" }
}

# public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "private" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
# load balancer
resource "aws_lb" "wordpress" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
}

resource "aws_lb_target_group" "wordpress_tg" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
}

# s3 bucket for terraform state
resource "aws_s3_bucket" "b" {
  bucket = "my-unique-terraform-state-bucket-1234567890"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "b" {
  bucket = aws_s3_bucket.b.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
