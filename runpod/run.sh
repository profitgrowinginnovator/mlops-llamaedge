#!/bin/bash

# Load variables from .env file
export $(grep -v '^#' ../.env | xargs)

# Set Terraform variables
export TF_VAR_runpod_api_key=$RUNPOD_API_KEY
