provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# 最新のNginxイメージ
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

# 変数の宣言
variable "ports" {
  default = [8080, 8081]
}

variable "name" {
  default = "darmaso-nginx"
}

# コンテナ起動
resource "docker_container" "nginx" {
  # 下記の数だけresourceを作って欲しい！というものになるみたい
  count = "${length(var.ports)}"

  # 三項演算子はサポートされてるみたい
  name = "${count.index % 2 == 0 ? "${var.name}-a-${count.index+1}" : "${var.name}-b-${count.index+1}"}"
  image = "${docker_image.nginx.latest}"
  ports {
    internal = 80
    external = "${var.ports[count.index]}"
  }
}

