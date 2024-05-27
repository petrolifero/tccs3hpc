variable "cluster_size" {
  default = 5
  type    = number
}

variable "cluster_ami" {
  default = "ami-0cca9f4a2327918eb"
  type    = string
}

variable "cluster_instance_type" {
  default = "t3.large"
  type    = string
}