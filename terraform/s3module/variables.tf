variable "cluster_instance_type" {
    type=string
}

variable "cluster_ami" {
    type=string
}

variable "cluster_size" {
type=string
}

variable "spot_price" {
   type=number
}

locals {
    pureIdentifier=var.cluster_instance_type
}