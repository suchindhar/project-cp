provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-05e00961530ae1b55"
  instance_type = "t2.medium"
  key_name      = "new.pem"
  security_groups = ["open group"]  # Associate the "open group" security group with the master instance

  tags = {
    Name = "K8s-Master"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -",
      "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("path-to-your-private-key/new.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "k8s_worker" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.medium"
  key_name      = "new.pem"
  security_groups = ["open group"]  # Associate the "open group" security group with the worker instances

  tags = {
    Name = "K8s-Worker-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k8s_master.public_ip}:6443 K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token) sh -"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("path-to-your-private-key/new.pem")
      host        = self.public_ip
    }
  }
}

output "k8s_master_ip" {
  value = aws_instance.k8s_master.public_ip
}
