# Pin this after recording an image tag that works on your chosen Vast.ai GPU.
ARG VLLM_IMAGE=vllm/vllm-openai:latest
FROM ${VLLM_IMAGE}

WORKDIR /workspace/app
COPY requirements.txt ./
RUN python -m pip install --no-cache-dir -r requirements.txt
COPY scripts/ ./scripts/
RUN chmod +x ./scripts/*.sh

EXPOSE 18001
ENTRYPOINT []
CMD ["./scripts/start_vllm.sh"]
