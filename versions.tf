terraform {
  required_version = ">= 1.14"

  # Un module ne declare que ses contraintes : aucun bloc provider ici,
  # le provider est herite de l'environnement appelant.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
