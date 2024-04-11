terraform {
  required_providers {
    awsutils = {
      source  = "cloudposse/awsutils"
      version = ">= 0.19.0"
    }
  }
}

provider "awsutils" {
  region = var.region
}
