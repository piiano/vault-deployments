###########################
### Cloud Load Balancer ###
###########################

variable "prefix" {
  description = "A prefix to be added to resource names"
  type        = string
}

variable "region" {
  description = "The region where resources will be deployed"
  type        = string
}

variable "network_id" {
  type = string
}

variable "ssl_certificate" {
  description = "SSL certificate for Cloud Load Balancer"
  type        = string
}

variable "ssl_certificate_private_key" {
  description = "SSL certificate private key for Cloud Load Balancer"
  type        = string
}

variable "frontend_ip_range" {
  description = "Cloud Load Balancer Frontend /26 CIDR range"
  type        = string
  default     = "10.8.1.0/26"
}

variable "backend_ip_range" {
  description = "Cloud Load Balancer Backend /26 CIDR range"
  type        = string
  default     = "10.8.0.64/26"
}

variable "cloud_run_name" {
  type = string
}

variable "timeout" {
  type    = number
  default = 30
}
