variable "cluster_instance_type" {
    type=string
}

variable "cluster_size" {
    type=number
}

variable "cluster_ami" {
    type=string
}

variable "vpc" {
type=string
}

variable "key_name" {
type=string
}

variable "security_group_ids" {
type=list(string)
}

variable "subnet_id" {
type=string
}

variable "pure_identifier" {
type=string
}