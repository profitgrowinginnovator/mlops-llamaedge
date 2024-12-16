#!/bin/bash
docker buildx build --progress=plain -t wasmedge:ubuntu24.04-cuda --load .
