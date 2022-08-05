locals {
  vpc_id = "vpc-0eab827eb9d215e5a"
  ssh_user = "ubuntu"
  private_key_path = "${path.module}/terraform_key"
  my_ami = "ami-08d4ac5b634553e16"
}


provider "aws" {
  region = "us-east-1"
  access_key = "AKIAZVUFVRKLNQWKK4U7"
  secret_key = "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"
}

resource "aws_key_pair" "login" {
  key_name = "login"
  public_key = file("${local.private_key_path}.pub")
}

resource "aws_security_group" "projectaccess"{
  name = "projectaccess"
  vpc_id = local.vpc_id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami = local.my_ami
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.projectaccess.id]
  key_name = aws_key_pair.login.key_name
 
  tags = {
    Name = "Demo test"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = local.ssh_user
    private_key  = file(local.private_key_path)
    timeout = "4m"
  }

  provisioner "remote-exec"{
    inline = [
      "echo 'foo'"
    ]
  }

  provisioner "local-exec"{
    command = "echo ${self.public_ip} ansible_user=${local.ssh_user} > myhosts"
  }
  
  provisioner "local-exec"{
    command = "ansible-playbook -i myhosts --private-key ${local.private_key_path} wp_deploy.yml"
  }

}

output "instance_ip" {
  value = aws_instance.web.public_ip
}

