terraform {
  required_providers {
    awsutils = {
      source  = "cloudposse/awsutils"
      version = ">= 0.18.1"
    }
  }
}

provider "awsutils" {
  region = var.region
}
