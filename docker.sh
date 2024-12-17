#!/bin/bash
docker buildx build --progress=plain --target ubuntu-run -t wasmedge:ubuntu24.04-cuda --load .
docker buildx build --progress=plain --target tiny-llama -t wasmedge:tiny-llama-cuda --load .
