module "admin" {
  source = "../module/web_app"
  web_app_subnet_id = "${var.subnet_id}"
}

module "app" {
  source = "../module/web_app"
  web_app_subnet_id = "${var.subnet_id}"
}

module "lp" {
  source = "../module/web_app"
  web_app_subnet_id = "${var.subnet_id}"
}
