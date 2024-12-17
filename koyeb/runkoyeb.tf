terraform {
  required_providers {
    koyeb = {
      source  = "koyeb/koyeb"
    }
  }
}
provider "koyeb" {}

variable "koyeb_token" {
  description = "Koyeb API Token"
  type        = string
}

variable "app_name" {
  description = "Application name for Koyeb"
  type        = string
  default     = "tinyllama-gpu-app"
}

variable "service_name" {
  description = "Service name for Koyeb"
  type        = string
  default     = "tinyllama-service"
}

resource "koyeb_app" "my-app" {
  name = var.app_name
}



resource "koyeb_service" "tinyllama_service" {
  app_name = var.app_name
  definition {
    name = var.service_name
    instance_types {
      type = "gpu-nvidia-rtx-4000-sff-ada"
    }
    ports {
      port     = 8080
      protocol = "http"
    }
    scalings {

      min = 1
      max = 1
 
    }


    # Mount directories for model and wasm file

    routes {
      path = "/"
      port = 8080
    }
    health_checks {
      http {
        port = 8080
        path = "/v1/models"
      }
    }


    regions = ["fra"]
    docker {
      image = "docker.io/profitgrowinginnovator/wasmedge:tiny-llama-cuda"
    }
  }

  depends_on = [
    koyeb_app.my-app
  ]
}


# Output the service endpoint
output "koyeb_service_url" {
  value = "https://${koyeb_service.tinyllama_service.app_id}.koyeb.app"
}

