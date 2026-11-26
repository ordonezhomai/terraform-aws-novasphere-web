variable "name" {
  description = "Prefixe des ressources, ex : novasphere-dev"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,28}$", var.name))
    error_message = "name : 3 a 28 caracteres, minuscules, chiffres et tirets (limite de nommage des ALB et target groups)."
  }
}

variable "environment" {
  description = "Nom de l'environnement (dev, prod), affiche sur la page et passe au script de demarrage"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment doit valoir dev ou prod."
  }
}

variable "vpc_id" {
  description = "VPC dans lequel creer les Security Groups et le target group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets publics, au moins deux zones de disponibilite"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Il faut au moins deux subnets (deux zones de disponibilite)."
  }
}

variable "ami_id" {
  description = "AMI des instances (Amazon Linux 2023 : AWS CLI incluse)"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "Profil d'instance donnant la lecture du secret dans Parameter Store"
  type        = string
}

variable "secret_parameter_name" {
  description = "Chemin du secret dans Parameter Store, ex : /novasphere/dev/db_password"
  type        = string

  validation {
    condition     = can(regex("^/novasphere/(dev|prod)/", var.secret_parameter_name))
    error_message = "Le secret doit vivre sous /novasphere/dev/ ou /novasphere/prod/."
  }
}

variable "min_size" {
  description = "Nombre minimal d'instances (au moins 2 : une par zone)"
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 2
    error_message = "min_size doit valoir au moins 2."
  }
}

variable "max_size" {
  description = "Nombre maximal d'instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Nombre d'instances souhaite"
  type        = number
  default     = 2
}
