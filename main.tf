provider "aws" {
    region = "eu-west-3"
}

variable "username" {
  default = "ubuntu"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Allow inbound ssh"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["75.71.5.185/32", "90.35.197.186/32"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["75.71.5.185/32"]
  }
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["75.71.5.185/32", "90.35.197.186/32"]
  }
  ingress {
    from_port = 8384
    to_port = 8384
    protocol = "tcp"
    cidr_blocks = ["174.209.28.180/32"]
  }
}

resource "aws_instance" "paysansorcier" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name	= "pierre"
  security_groups = ["default", "${aws_security_group.ssh.name}"]
  availability_zone = "eu-west-3a"
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
    delete_on_termination = "false"
  }
}

output "ip" {
  value = "${aws_instance.paysansorcier.public_ip}"
}

