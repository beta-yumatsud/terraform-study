provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

# VPC
resource "aws_vpc" "wp-vpc" {
  cidr_block = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "wp-vpc"
  }
}

# Subnet
resource "aws_subnet" "wp-public-subnet-a" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  cidr_block = "10.1.11.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags {
    Name = "wp-public-subnet-a"
  }
}

resource "aws_subnet" "wp-private-subnet-a" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  cidr_block = "10.1.15.0/24"
  availability_zone = "ap-northeast-1a"
  tags {
    Name = "wp-private-subnet-a"
  }
}

resource "aws_subnet" "wp-public-subnet-c" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  cidr_block = "10.1.51.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags {
    Name = "wp-public-subnet-c"
  }
}

resource "aws_subnet" "wp-private-subnet-c" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  cidr_block = "10.1.55.0/24"
  availability_zone = "ap-northeast-1c"
  tags {
    Name = "wp-private-subnet-c"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "wp-gw" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  tags {
    Name = "wp-gw"
  }
}

# Route table
resource "aws_route_table" "wp-public-rtb" {
  vpc_id = "${aws_vpc.wp-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp-gw.id}"
  }
  tags {
    Name = "wp-public-rtb"
  }
}

resource "aws_route_table_association" "wp-public-a" {
  subnet_id = "${aws_subnet.wp-public-subnet-a.id}"
  route_table_id = "${aws_route_table.wp-public-rtb.id}"
}

resource "aws_route_table_association" "wp-public-c" {
  subnet_id = "${aws_subnet.wp-public-subnet-c.id}"
  route_table_id = "${aws_route_table.wp-public-rtb.id}"
}

# Security Group
resource "aws_security_group" "wp-web-dmz" {
  name = "wp-web-dmz"
  description = "WordPress Web App security group"
  vpc_id = "${aws_vpc.wp-vpc.id}"
  tags {
    Name = "wp-web-dmz"
  }
}

resource "aws_security_group" "wp-db" {
  name = "wp-db"
  description = "WordPress MySQL Security Group"
  vpc_id = "${aws_vpc.wp-vpc.id}"
  tags {
    Name = "wp-db"
  }
}

resource "aws_security_group" "wp-elb-sg" {
  name        = "wp-elb-sg"
  description = "WordPress ELB Security Group"

  vpc_id = "${aws_vpc.wp-vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ensure the VPC has an Internet gateway or this step will fail
  depends_on = ["aws_internet_gateway.wp-gw"]
}

resource "aws_security_group_rule" "ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.wp-web-dmz.id}"
}

resource "aws_security_group_rule" "web" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  //cidr_blocks = ["0.0.0.0/0"]
  source_security_group_id = "${aws_security_group.wp-elb-sg.id}"
  security_group_id = "${aws_security_group.wp-web-dmz.id}"
}

resource "aws_security_group_rule" "all" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.wp-web-dmz.id}"
}

resource "aws_security_group_rule" "db" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = "${aws_security_group.wp-web-dmz.id}"
  security_group_id = "${aws_security_group.wp-db.id}"
}

# DB Subnet Group
resource "aws_db_subnet_group" "wp-dbsubnet" {
  name = "wp-dbsubnet"
  description = "WordPress DB Subnet"
  subnet_ids = ["${aws_subnet.wp-private-subnet-a.id}", "${aws_subnet.wp-private-subnet-c.id}"]
  tags {
    Name = "wp-dbsubnet"
  }
}

# DB Instance
resource "aws_db_instance" "wp-db" {
  identifier = "wp-dbinstance"
  allocated_storage = 20
  engine = "mysql"
  engine_version = "5.6.40"
  instance_class = "db.t2.micro"
  storage_type = "gp2"
  username = "${var.aws_db_username}"
  password = "${var.aws_db_password}"
  multi_az = true
  backup_retention_period = 1
  vpc_security_group_ids = ["${aws_security_group.wp-db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.wp-dbsubnet.name}"
}

resource "aws_instance" "wp-web-app1" {
  ami = "ami-00a5245b4816c38e6"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.wp-web-dmz.id}"]
  subnet_id = "${aws_subnet.wp-public-subnet-a.id}"
  associate_public_ip_address = true
  root_block_device = {
    volume_type = "gp2"
    volume_size = "20"
  }
  ebs_block_device = {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    volume_size = "100"
  }
  tags {
    Name = "wp-web-app1"
  }
}

resource "aws_instance" "wp-web-app2" {
  ami = "ami-00a5245b4816c38e6"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  vpc_security_group_ids = ["${aws_security_group.wp-web-dmz.id}"]
  subnet_id = "${aws_subnet.wp-public-subnet-c.id}"
  associate_public_ip_address = true
  root_block_device = {
    volume_type = "gp2"
    volume_size = "20"
  }
  ebs_block_device = {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    volume_size = "100"
  }
  //user_data = "${file("userdata.sh")}"
  tags {
    Name = "wp-web-app2"
  }
}

# ELB(ALB) 証明書を設定する場合はどうするかは後々見ておく
resource "aws_elb" "wp-elb" {
  name = "wp-elb"

  # The same availability zone as our instance
  subnets = ["${aws_subnet.wp-public-subnet-a.id}", "${aws_subnet.wp-public-subnet-c.id}"]

  security_groups = ["${aws_security_group.wp-elb-sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  # The instance is registered automatically
  instances                   = ["${aws_instance.wp-web-app1.id}", "${aws_instance.wp-web-app2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_lb_cookie_stickiness_policy" "default" {
  name                     = "lbpolicy"
  load_balancer            = "${aws_elb.wp-elb.id}"
  lb_port                  = 80
  cookie_expiration_period = 1800
}

/**
 Auto Scalingなどもゆくゆく見ておくと良いかも
 https://github.com/terraform-providers/terraform-provider-aws/tree/master/examples/asg
 */

# S3
# 静的WebページのHostingをしたい場合にどうするか要検討
resource "aws_s3_bucket" "wp-s3" {
  bucket = "${var.bucket_name}"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid" : "PublicReadForGetBucketObjects",
    "Effect" : "Allow",
    "Principal" : "*",
    "Action" : ["s3:GetObject"],
    "Resource" : ["arn:aws:s3:::${var.bucket_name}/*"]
  }]
}
POLICY
  website_endpoint = "index.html"
  // リダイレクトルールとかも作れる模様。おそらく、xmlのような形式を上記のようにRaw文字列で指定する感じか
}

data "aws_s3_bucket" "selected" {
  bucket = "${var.bucket_name}"
}

# 下記は多分いらない？(よくわからない)
resource "aws_s3_bucket_object" "wp-s3-object" {
  bucket = "${aws_s3_bucket.wp-s3.id}"
  key = "object-uploaded-via-creds"
  source = "${path.module}/index.html"
}

# Route53
data "aws_route53_zone" "selected" {
  name = "darmaso.com."
  comment = "aws study"
}
resource "aws_route53_record" "wp-s3-record" {
  name = "${data.aws_route53_zone.selected.name}"
  type = "A"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
}

# CloudFront
resource "aws_cloudfront_distribution" "this" {
  "default_cache_behavior" {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    "forwarded_values" {
      "cookies" {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id = ""
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }
  price_class = "PriceClass_All"
  enabled = false
  "origin" {
    domain_name = "${data.aws_s3_bucket.selected.bucket_domain_name}"
    origin_id = "s3-selected-bucket"
  }
  "restrictions" {
    "geo_restriction" {
      restriction_type = ""
    }
  }
  "viewer_certificate" {}
}
