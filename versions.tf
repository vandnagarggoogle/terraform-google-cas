terraform {
  required_version = ">= 1.5.7" # Lowered from 1.12.2
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0" # Keeps support for recent CA Service features
    }
  }
}
