variable "user" {}
variable "key_path" {}
variable "private_key" {}
variable "primary_consul" {}
variable "nginx_server_count" {}
variable "subnet_id" {}
variable "xlb_sg_id" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "name"
    values = ["ubuntu-16-nginx*"]
  }
}


resource "aws_instance" "nginx" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    count = "${var.nginx_server_count}"
    subnet_id = "${var.subnet_id}"
    vpc_security_group_ids = ["${var.xlb_sg_id}"]
    tags = {
      env = "xlb-demo"
    }
    connection {
        user = "${var.user}"
        private_key = "${var.private_key}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.primary_consul} > /tmp/consul-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/scripts/install.sh"
        ]
    }

    provisioner "remote-exec" {
        inline = [
            "sudo systemctl enable consul.service",
            "sudo systemctl start consul"
        ]
    }
    provisioner "file" {
        source = "${path.module}/scripts/secret_page.sh",
        destination = "/tmp/secret_page.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "sudo chmod +x /tmp/secret_page.sh",
        ]
    }

}
