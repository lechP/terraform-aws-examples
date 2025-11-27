variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}
