variable "name" {
  description = "Prefixe des ressources, ex : novasphere-dev"
  type        = string
}

variable "environment" {
  description = "Nom de l'environnement (dev, prod), affiche sur la page"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment doit valoir dev ou prod."
  }
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets publics, au moins deux zones"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Il faut au moins deux subnets (deux zones de disponibilite)."
  }
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_profile_name" {
  description = "Profil d'instance donnant la lecture du secret dans Parameter Store"
  type        = string
}

variable "secret_parameter_name" {
  description = "Chemin du secret dans Parameter Store, ex : /novasphere/dev/db_password"
  type        = string
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}
