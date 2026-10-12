# Qwen (optional local SLM)

Qwen is an optional local LLM endpoint used by the Python API when configured. The API can use
its built-in fallback behavior when this server or its model is unavailable. Running this local
server keeps LLM requests on the machine.

Put these two files in this folder (they are not in git):

- `llamafile-0.10.5.exe`
- `Qwen3.5-4B-Q4_K_M.gguf`

Run from this folder (PowerShell):

```
.\llamafile-0.10.5.exe -m ".\Qwen3.5-4B-Q4_K_M.gguf" --server
```

It listens on http://127.0.0.1:8080 which matches `LOCAL_LLM_URL` in `.env.local`.
`LOCAL_LLM_MODEL` must stay `Qwen3.5-4B-Q4_K_M`.

`LOCAL_LLM_API_KEY` is sent as a Bearer header. The command above starts the server without
an API key, so the header is simply ignored. If you start llamafile with `--api-key`, use the
same value in `.env.local`.

Check it: open http://127.0.0.1:8080 in a browser, or call `GET http://127.0.0.1:8000/api/health`
on the backend and look at `localLlm.up`.
