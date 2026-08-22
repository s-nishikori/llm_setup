import argparse
import os
import sys
from pathlib import Path

from openai import APIConnectionError, APIStatusError, OpenAI


PROJECT_DIR = Path(__file__).resolve().parent


def load_dotenv() -> None:
    """Load simple KEY=VALUE entries without overwriting the current environment."""
    env_path = PROJECT_DIR / ".env"
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        os.environ.setdefault(key, value)


def create_client() -> tuple[OpenAI, str]:
    load_dotenv()
    api_key = os.getenv("VLLM_API_KEY", "").strip()
    if not api_key or api_key.startswith("REPLACE_WITH_"):
        raise RuntimeError(
            "VLLM_API_KEY is not configured. Copy .env.example to .env and set the API key."
        )

    base_url = os.getenv("OPENAI_BASE_URL", "http://localhost:8080/v1").rstrip("/")
    model = os.getenv("SERVED_MODEL_NAME", "qwen")
    return OpenAI(base_url=base_url, api_key=api_key), model


def show_status(client: OpenAI) -> None:
    models = client.models.list()
    names = [model.id for model in models.data]
    print("Connected to vLLM.")
    print("Available models: " + (", ".join(names) if names else "(none)"))


def run_chat(client: OpenAI, model: str) -> None:
    messages: list[dict[str, str]] = []
    print(f"Connected model: {model}")
    print("Commands: /clear resets the conversation, /exit quits.\n")

    while True:
        try:
            prompt = input("You> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye.")
            return

        if not prompt:
            continue
        if prompt.lower() in {"/exit", "/quit", "exit", "quit"}:
            print("Bye.")
            return
        if prompt.lower() == "/clear":
            messages.clear()
            print("Conversation cleared.\n")
            continue

        messages.append({"role": "user", "content": prompt})
        print("AI> ", end="", flush=True)
        answer_parts: list[str] = []
        try:
            stream = client.chat.completions.create(
                model=model,
                messages=messages,
                stream=True,
            )
            for chunk in stream:
                text = chunk.choices[0].delta.content or ""
                if text:
                    print(text, end="", flush=True)
                    answer_parts.append(text)
            print("\n")
            messages.append({"role": "assistant", "content": "".join(answer_parts)})
        except (APIConnectionError, APIStatusError) as exc:
            messages.pop()
            print(f"\nRequest failed: {exc}\n", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Chat with the Vast.ai vLLM server.")
    parser.add_argument("--status", action="store_true", help="check the API connection")
    args = parser.parse_args()

    try:
        client, model = create_client()
        if args.status:
            show_status(client)
        else:
            run_chat(client, model)
    except (RuntimeError, APIConnectionError, APIStatusError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
