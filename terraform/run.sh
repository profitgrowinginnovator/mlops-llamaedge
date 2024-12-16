#!/bin/bash
# Load .env file
set -a
[ -f ../.env ] && . ../.env
set +a

# Export variables with TF_VAR_ prefix
export TF_VAR_project_id=$PROJECT_ID
export TF_VAR_region=$REGION
export TF_VAR_model_path=$MODEL_PATH
export TF_VAR_wasm_path=$WASM_PATH

# Run Terraform
terraform "$@"
