terraform {
  required_version = ">= 0.12.28"

  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = ">= 2.44"
    }
  }
}
