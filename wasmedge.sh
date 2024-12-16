#!/bin/bash
docker run --rm -it --runtime=nvidia --gpus all -v $HOME/docker/model:/model -v $HOME/docker/app:/app -p 8080:8080 profitgrowinginnovator/wasmedge:ubuntu24.04-cuda $@

