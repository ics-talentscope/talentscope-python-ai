# ── TalentScope Qwen LLM Server (llama.cpp server) ──
# Uses the pre-built llama.cpp server image and mounts the GGUF model at runtime.
#
# The Qwen model file (Qwen3.5-4B-Q4_K_M.gguf, ~2.7 GB) is NOT baked into the
# image. It is bind-mounted via docker-compose to keep the image small.

FROM ghcr.io/ggml-org/llama.cpp:server

# Default env vars (overridable via docker-compose / env)
ENV LLAMA_ARG_MODEL=/models/Qwen3.5-4B-Q4_K_M.gguf
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080
ENV LLAMA_ARG_CTX_SIZE=4096

EXPOSE 8080
