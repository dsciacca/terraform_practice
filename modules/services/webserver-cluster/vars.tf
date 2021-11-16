variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "elb_port" {
  description = "The port the ELB will use for HTTP requests"
  default = 80
}

variable "cidr_range" {
  description = "The CIDR ranges to allow ingress traffic from"
  default = ["0.0.0.0/0"]
}

variable "http_protocol" {
  description = "HTTP protocol to use: HTTP or HTTPS"
  default = "http"
}