provider "aws" {
	access_key = "${var.access_key}"
	secret_key = "${var.secret_key}"
	region 	   = "${var.region}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "personal-site" {
	name 		= "personal-site"
	description = "allow traffic on port 8080"

	ingress {
		from_port 	= 8080
		to_port 	= 8080
		protocol  	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port 	= 22
		to_port 	= 22
		protocol  	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port 	= 0
		to_port 	= 0
		protocol  	= "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_instance" "site-host" {
	ami           	= "${data.aws_ami.ubuntu.id}"
  instance_type 	= "t2.micro"
	key_name 				= "personal-site"
	security_groups = ["${aws_security_group.personal-site.name}"]

	provisioner "file" {
		source 			= "/home/whammond/go/bin/personal-site"
		destination 	= "./personal-site"
		
		connection {
			type        = "ssh"
			user 		= "ubuntu"
			private_key = "${file("~/.ssh/personal-site.pem")}"
		}
	}

	provisioner "remote-exec" {
		inline = [
			"sudo mv personal-site /bin/personal-site",
			"chmod +x /bin/personal-site",
			"personal-site &"	
		]	

		connection {
			type        = "ssh"
			user 		= "ubuntu"
			private_key = "${file("~/.ssh/personal-site.pem")}"
		}
	}
}
