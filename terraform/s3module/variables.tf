variable "cluster_instance_type" {
    type=string
}

variable "cluster_ami" {
    type=string
}

variable "cluster_size" {
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

variable "role_name" {
type=string
}

variable "instance_profile" {
type=string
}

variable "pure_identifier" {
type=string
}