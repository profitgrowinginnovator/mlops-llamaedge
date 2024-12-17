terraform {
  required_providers {
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.0.0"
    }
  }
}

provider "terracurl" {}

variable "runpod_api_key" {
  description = "RunPod API key"
  type        = string
}

variable "payload" {
  description = "JSON payload for creating a pod on RunPod"
  type        = string
  default     = <<EOT
{
  "image": "profitgrowinginnovator/wasmedge:ubuntu24.04-cuda",
  "gpu": "RTX A4000",
  "min_worker": "0",
  "env": {
    "MODEL_PATH": "https://huggingface.co/NightShade9x9/TinyLlama-1.1B-Chat-v1.0-Q8_0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0-q8_0.gguf",
    "WASM_PATH": "https://github.com/LlamaEdge/LlamaEdge/releases/download/0.15.0/llama-api-server.wasm"
  },
  "command": [
    "--dir", ".:.",
    "--env", "LLAMA_LOG=info",
    "--nn-preload", "default:GGML:AUTO:/model/tinyllama-1.1b-chat-v1.0.q8_0.gguf",
    "/app/llama-api-server.wasm",
    "--prompt-template", "llama-3-chat"
  ]
}
EOT
}

# Terracurl request to create and destroy a pod on RunPod
resource "terracurl_request" "runpod_pod_create" {
  name          = "runpod-pod-create"
  url           = "https://api.runpod.ai/v2/pods/run"
  method        = "POST"
  request_body  = var.payload

  headers = {
    Authorization = "Bearer ${var.runpod_api_key}"
    Content-Type  = "application/json"
  }

  response_codes = [200, 201]
}


output "runpod_pod_id" {
  value = jsondecode(terracurl_request.runpod_pod_create.response).pod_id
}

# Step 2: Destroy the pod using a separate resource
resource "null_resource" "runpod_pod_destroy" {
  depends_on = [terracurl_request.runpod_pod_create]

  provisioner "local-exec" {
    command = <<EOT
      curl -X DELETE \
      -H "Authorization: Bearer ${var.runpod_api_key}" \
      https://api.runpod.io/v2/pods/$(echo '${terracurl_request.runpod_pod_create.response}' | jq -r '.pod_id')
    EOT
  }
}
