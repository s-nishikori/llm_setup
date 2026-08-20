import os

from openai import OpenAI


client = OpenAI(
    base_url=os.getenv("OPENAI_BASE_URL", "http://localhost:8000/v1"),
    api_key=os.environ["VLLM_API_KEY"],
)

response = client.chat.completions.create(
    model=os.getenv("SERVED_MODEL_NAME", "qwen"),
    messages=[{"role": "user", "content": "PythonとGoの違いを簡潔に説明して。"}],
)
print(response.choices[0].message.content)
