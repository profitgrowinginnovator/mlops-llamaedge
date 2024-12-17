#!/bin/bash

# Load variables from .env file
export $(grep -v '^#' ../.env | xargs)

# Set Terraform variables
export TF_VAR_koyeb_token=$KOYEB_TOKEN
