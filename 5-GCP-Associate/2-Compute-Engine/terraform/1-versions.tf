terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.0.1"
    }
  }
  backend "gcs" {
    bucket = "polomapp"
    prefix = "dev-polom" # create this folder
    credentials = "/home/ubuntu/terraform-sa-key.json"
  }
}
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = "/home/ubuntu/terraform-sa-key.json"
}

