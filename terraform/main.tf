resource "google_project_service" "enable_apis" {
  for_each = toset([
    "run.googleapis.com",          # Cloud Run API
    "cloudbuild.googleapis.com",   # Cloud Build API
    "compute.googleapis.com",      # Compute Engine API
    "storage.googleapis.com"       # Cloud Storage API
  ])
  service = each.key
}
# Create Service Account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

# Assign Permissions to the Service Account
resource "google_project_iam_member" "cloud_run_roles" {
  for_each = toset([
    "roles/run.admin",             # Allow Cloud Run admin operations
    "roles/storage.objectViewer",  # Access Cloud Storage files
    "roles/compute.viewer"         # Access GPU information
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
  role    = each.key
}

# Create Artifact Registry for Docker Images
resource "google_artifact_registry_repository" "docker_repo" {
  repository_id         = "docker-repo"
  format       = "DOCKER"
  location     = var.region
  description  = "Repository for Docker images"
}

