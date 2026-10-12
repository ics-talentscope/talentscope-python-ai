# TalentScope Python AI services

This repository contains two separately deployable AI components:

- `faceproj/` is the FaceNet identity comparison API. Deploy it to Render from this repository using `render.yaml`. Its `/health` endpoint is the health check; configure `FACE_MATCH_API_KEY` to the same value on the API service and this service.
- `qwen/` is the optional local Qwen/llama.cpp server. The model weights and executable are intentionally not included in Git. For local use, provide the model file and start the llama.cpp server as described in `qwen/README.md`.

The Face Match blueprint uses a paid Render instance and persistent model cache disk so the PyTorch service has memory for model inference and avoids downloading the model weights on every restart. Configure the Python API's `FACE_MATCH_SERVICE_URL` with the deployed service's HTTPS URL.

Qwen is not included in the Render blueprint because its multi-gigabyte model file is not in this repository. To use a hosted LLM, supply a reachable compatible endpoint through the Python API's `LOCAL_LLM_URL`; otherwise the API retains its built-in fallback behavior.
