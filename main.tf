provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic inbound from a specific IP"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  tags = {
    Name = "${var.name_tag}"
  }
}

resource "tls_private_key" "andrew_development_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "andrew_development_key" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.andrew_development_key.public_key_openssh}"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "${var.name_tag}"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "${var.name_tag}"
  }
}

resource "aws_network_interface" "my_nic" {
  subnet_id   = "${aws_subnet.my_subnet.id}"
  private_ips = ["10.0.0.10"]

  security_groups = ["${aws_security_group.allow_ssh.id}"]

  tags = {
    Name = "${var.name_tag}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  tags = {
    Name = "${var.name_tag}"
  }  
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.my_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.andrew_development_key.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.my_nic.id}"
    device_index         = 0
  }

  tags = {
    Name = "${var.name_tag}"
  }
}

resource "aws_eip" "elastic_ip" {
  vpc = true

  instance                  = "${aws_instance.web.id}"
  associate_with_private_ip = "${aws_network_interface.my_nic.private_ip}"
  depends_on                = ["aws_internet_gateway.gw"]
  
  tags = {
    Name = "${var.name_tag}"
  }
}

resource "local_file" "local_ssh_keyfile" {
  content = "${tls_private_key.andrew_development_key.private_key_pem}"
  filename = "${path.module}/${aws_key_pair.andrew_development_key.key_name}.pem"
}