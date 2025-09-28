# 1. Project ID Variable
variable "project_id" {
  description = "The ID of the Google Cloud Project where resources will be created."
  type        = string
  default     = "terraform-470417"
}

# 2. Region Variable
variable "region" {
  description = "The Google Cloud region to deploy resources (e.g., us-central1)."
  type        = string
  default     = "us-central1" # Or another preferred default
}