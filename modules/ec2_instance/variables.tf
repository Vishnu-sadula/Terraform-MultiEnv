variable "instance_name" {
  type    = string
  default = "zenith"
}

variable "ami" {
  description = "ami id (probably ubuntu machine)"
}

variable "instance_type" {
  description = "type of instance"
}