provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Required APIs
resource "google_project_service" "enable_apis" {
  for_each = toset([
    "run.googleapis.com",          # Cloud Run API
    "cloudbuild.googleapis.com",   # Cloud Build API
    "compute.googleapis.com",      # Compute Engine API
    "storage.googleapis.com"       # Cloud Storage API
  ])
  service = each.key
  disable_on_destroy  = true
  disable_dependent_services=true
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

# Provision a Cloud Run Service
resource "google_cloud_run_service" "cloud_run_service" {
  name     = "gpu-llama-service"
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/instance-class" = "G1"
        "run.googleapis.com/accelerator"   = "nvidia-l4"  # Specify GPU type
        "autoscaling.knative.dev/minScale" = "1"                # Ensure one instance is always running
      }
    }
    spec {
      containers {
        image = "profitgrowinginnovator/wasmedge:ubuntu24.04-cuda"  # Docker image

        # Environment Variables for Remote URLs
        env {
          name  = "MODEL_PATH"
          value = "https://huggingface.co/NightShade9x9/TinyLlama-1.1B-Chat-v1.0-Q8_0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0-q8_0.gguf"
        }
        env {
          name  = "WASM_PATH"
          value = "https://github.com/LlamaEdge/LlamaEdge/releases/download/0.15.0/llama-api-server.wasm"
        }

        # Resources for GPU Support
        resources {
          limits = {
            "nvidia.com/gpu" = "1"   # Request GPU
            "memory"         = "16Gi"
            "cpu"            = "4"
          }
        }

        # Command Arguments for the Docker Container
        args = [
          "--dir", ".:.",
          "--env", "LLAMA_LOG=info",
          "--nn-preload", "default:GGML:AUTO:/model/tinyllama-1.1b-chat-v1.0-q8_0.gguf",
          "/app/llama-api-server.wasm",
          "--prompt-template", "llama-3-chat"
        ]
      }

    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Output Cloud Run URL
output "cloud_run_url" {
  value = google_cloud_run_service.cloud_run_service.status[0].url
}

