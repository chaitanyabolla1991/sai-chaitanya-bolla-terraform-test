variable "autoscaling_group_name" {}
variable "load_balancer_url" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}

