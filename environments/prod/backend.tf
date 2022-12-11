terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.45.0"
    }
  }
  backend "gcs" {
    bucket = "timeseries-mlops-tfstate"
    prefix = "env/prod"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
