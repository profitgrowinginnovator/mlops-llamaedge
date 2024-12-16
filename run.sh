#!/bin/bash
./wasmedge.sh --dir .:. --env LLAMA_LOG=info \
     --nn-preload default:GGML:AUTO:/model/tinyllama-1.1b-chat-v1.0.Q8_0.gguf \
    /app/llama-api-server.wasm \
    --prompt-template llama-3-chat
