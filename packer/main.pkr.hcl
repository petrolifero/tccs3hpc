packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "mpi-ami-ubuntu-22.04"
  instance_type = "t2.micro"
  region        = "sa-east-1"
  profile = "tcc"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230919"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = ["099720109477"]
  }
  force_deregister= true
  ssh_username = "ubuntu"
  temporary_key_pair_type = "ed25519"
}

build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo rm -rfv /var/lib/apt/lists/partial/",
      "sudo apt update",
      "sudo apt-cache search openmpi",
      "sudo apt dist-upgrade -y",
      "sudo apt install -y libopenmpi-dev openmpi-bin openmpi-common --no-install-recommends",
#      "wget -O - https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc | gpg --dearmor | sudo tee /usr/share/keyrings/fsx-ubuntu-public-key.gpg >/dev/null",
#      "sudo bash -c 'echo \"deb [signed-by=/usr/share/keyrings/fsx-ubuntu-public-key.gpg] https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu jammy main\" > /etc/apt/sources.list.d/fsxlustreclientrepo.list && apt-get update'",
#      "uname -r",
#      "sudo apt install -y linux-aws lustre-client-modules-aws"
    ]
  }
}
