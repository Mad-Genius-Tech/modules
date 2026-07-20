terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = ">= 3.1.0"
    }
  }
}
