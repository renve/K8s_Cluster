provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/home/vagrant/.aws/credentials"
  profile                 = "awsaml-362116776350-BAHSSO_Admin_Role"
}

terraform {
  backend "s3" {
    bucket = "terra-back"
    key    = "/backup-1"
    region = "us-east-1"
  }
}

resource "aws_security_group" "ivarela_sg" {
  name         = "ivarela_sg"
  description  = "Security Group for ivarela demo"
ingress {
    cidr_blocks = ["156.80.4.0/24","128.229.4.0/24",]  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }
ingress {
    cidr_blocks = ["156.80.4.0/24","128.229.4.0/24"]  
    from_port   = 8080 
    to_port     = 8080
    protocol    = "tcp"
  }
ingress {
    self        = true
    from_port   = 6443 
    to_port     = 6443
    protocol    = "tcp"
  }
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0",]
 }
}

resource "aws_instance" "k8s_master" {
  ami = "ami-02eac2c0129f6376b"
  instance_type = "t2.xlarge"
  key_name = "ivarela-demo"
  vpc_security_group_ids = ["${aws_security_group.ivarela_sg.name}"]
  tags {
    Name = "ivarela-k8s-master"
  }
  provisioner "file" {
    source      = "../scripts/install_master.sh"
    destination = "/tmp/install_master.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_master.sh",
      "sudo /tmp/install_master.sh",
    ]
  }
  provisioner "local-exec" {
    command = "ssh -o \"StrictHostKeyChecking no\" centos@${aws_instance.k8s_master.public_ip} 'kubeadm token create --print-join-command' >> ../scripts/join.sh"
  }
 
  connection {
    user = "centos"
    private_key = "${file("~/.ssh/id_rsa")}"
  }
}

resource "aws_instance" "node1" {

  depends_on = ["aws_instance.k8s_master"]

  ami = "ami-02eac2c0129f6376b"
  instance_type = "t2.xlarge"
  key_name = "ivarela-demo"
  vpc_security_group_ids = ["${aws_security_group.ivarela_sg.name}"]
 
  tags {
    Name = "ivarela-k8s-node1"
  }
 

  provisioner "file" {
     source      = "../scripts/install_node.sh"
     destination = "/tmp/install_node.sh"
  }

  provisioner "file" {
    source      ="../scripts/join.sh"
    destination ="/tmp/join.sh"
  }

  provisioner "remote-exec" { 
    inline = [
      "chmod +x /tmp/install_node.sh",
      "chmod +x /tmp/join.sh",
      "sudo /tmp/install_node.sh",
      "sudo /tmp/join.sh"
    ]
 }

 connection {
    user = "centos"
    private_key = "${file("~/.ssh/id_rsa")}" 
  }
}
