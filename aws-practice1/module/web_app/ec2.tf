resource "aws_instance" "admin" {
  count = 2
  ami = "ami-999999"
  instance_type = "t2.micro"
  subnet_id = "${var.web_app_subnet_id}"
}

resource "aws_instance" "app" {
  count = 2
  ami = "ami-999999"
  instance_type = "t2.micro"
  subnet_id = "${var.web_app_subnet_id}"
}

resource "aws_instance" "lp" {
  count = 2
  ami = "ami-999999"
  instance_type = "t2.micro"
  subnet_id = "${var.web_app_subnet_id}"
}
