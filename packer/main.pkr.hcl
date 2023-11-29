packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazon-linux" {
  ami_name      = "mpi-ami-amazon-linux"
  instance_type = "t2.micro"
  region        = "us-east-1"
  profile       = "tcc"
  source_ami_filter {
    filters = {
      image-id = "ami-0fa1ca9559f1892ec"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = ["amazon"]
  }
  force_deregister= true
  ssh_username = "ec2-user"
  temporary_key_pair_type = "ed25519"
}

build {
  name    = "learn-packer"
  sources = [
    "source.amazon-ebs.amazon-linux"
  ]

  provisioner "shell" {
    inline = [
      "sudo yum -y install openmpi-devel.x86_64",
      "sudo amazon-linux-extras install -y lustre",
      "sudo yum -y install git",
      "sudo yum -y install autoconf",
      "sudo yum -y install automake",
      "sudo yum -y install libcurl-devel.x86_64",
      "sudo yum -y install openssl-devel.x86_64",
      "sudo yum -y install libxml2-devel.x86_64 ",
      "sudo yum -y install tmux",
      "echo >>~/.bashrc",
      "echo 'export MPI_PYTHON2_SITEARCH=/usr/lib64/python2.7/site-packages/openmpi' >> ~/.bashrc",
      "echo 'export MPI_INCLUDE=/usr/include/openmpi-x86_64' >> ~/.bashrc",
      "echo 'export MANPATH=:/usr/share/man/openmpi-x86_64:/usr/share/man:/usr/local/share/man' >> ~/.bashrc",
      "echo 'export MPI_PYTHON_SITEARCH=/usr/lib64/python2.7/site-packages/openmpi' >> ~/.bashrc",
      "echo 'export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib' >> ~/.bashrc",
      "echo 'export MPI_LIB=/usr/lib64/openmpi/lib' >> ~/.bashrc",
      "echo 'export PATH=/usr/lib64/openmpi/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ec2-user/.local/bin:/home/ec2-user/bin' >> ~/.bashrc",
      "echo 'export MPI_BIN=/usr/lib64/openmpi/bin' >> ~/.bashrc",
      "echo 'export MPI_COMPILER=openmpi-x86_64' >> ~/.bashrc",
      "echo 'export _LMFILES_=/etc/modulefiles/mpi/openmpi-x86_64' >> ~/.bashrc",
      "echo 'export MPI_PYTHON3_SITEARCH=/usr/lib64/python3.7/site-packages/openmpi' >> ~/.bashrc",
      "echo 'export LOADEDMODULES=mpi/openmpi-x86_64' >> ~/.bashrc",
      "echo 'export MPI_SYSCONFIG=/etc/openmpi-x86_64' >> ~/.bashrc",
      "echo 'export MPI_SUFFIX=_openmpi' >> ~/.bashrc",
      "echo 'export MPI_MAN=/usr/share/man/openmpi-x86_64' >> ~/.bashrc",
      "echo 'export MPI_HOME=/usr/lib64/openmpi' >> ~/.bashrc",
      "echo 'export MPI_FORTRAN_MOD_DIR=/usr/lib64/gfortran/modules/openmpi' >> ~/.bashrc",
      "echo 'export PKG_CONFIG_PATH=/usr/lib64/openmpi/lib/pkgconfig' >> ~/.bashrc"
    ]
  }
}
