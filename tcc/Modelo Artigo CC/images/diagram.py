from diagrams import Diagram,Cluster
from diagrams.aws.compute import EC2
from diagrams.aws.storage import Fsx
from diagrams.aws.storage import S3
from diagrams.aws.network import VPC
from diagrams.aws.network import PrivateSubnet
from diagrams.aws.network import PublicSubnet
from diagrams.aws.general import Client


with Diagram("lustre",show=False):
    ansible = Client("ansible")
    with Cluster("publicSubnet"):
        public_host = EC2("access")
    with Cluster("privateSubnet"):
        private_hosts = [EC2("machine") for i in range(5)]
        lustre = Fsx("lustre")
        private_hosts >> lustre
    ansible >> public_host >> private_hosts

with Diagram("s3",show=False):
    ansible = Client("ansible")
    with Cluster("publicSubnet"):
        public_host = EC2("access")
    with Cluster("privateSubnet"):
        private_hosts = [EC2("machine") for i in range(5)]
        lustre = S3("S3")
        private_hosts >> lustre
    ansible >> public_host >> private_hosts
