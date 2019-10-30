variable "server_name" {
  default = "web-server"
}

variable "location" {
  type = map(string)
  default = {
    location1 = "westus2"
    locaiton2 = "westeurope"
  }
}

variable "subnets" {
  type    = list(string)
  default = ["10.0.1.10", "10.0.1.11"]
}

variable "live" {
  type    = string
  default = true
}

