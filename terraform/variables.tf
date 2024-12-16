variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "model_path" {
  description = "Path to the model file in GCS"
  type        = string
}

variable "wasm_path" {
  description = "Path to the WASM file in GCS"
  type        = string
}
cat 1_google_setup.tf 
provider "google" {
  project = var.project_id
  region  = var.region
}
