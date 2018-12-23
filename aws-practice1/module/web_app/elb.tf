resource "aws_elb" "admin" {
  name = "admin-elb"
  instances = ["${aws_instance.admin.*.id}"]
  subnets = ["subnet1"]
  # その他にもlistener, healthcheckの設定などが可能
}

resource "aws_elb" "app" {
  name = "app-elb"
  instances = ["${aws_instance.app.*.id}"]
  subnets = ["subnet1"]
  # その他にもlistener, healthcheckの設定などが可能
}

resource "aws_elb" "lp" {
  name = "lp-elb"
  instances = ["${aws_instance.lp.*.id}"]
  subnets = ["subnet1"]
  # その他にもlistener, healthcheckの設定などが可能
}
