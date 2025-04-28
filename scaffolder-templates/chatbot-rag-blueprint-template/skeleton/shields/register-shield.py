import os
from llama_stack_client import LlamaStackClient

LLAMA_STACK_ENDPOINT=os.getenv("LLAMA_STACK_ENDPOINT")

print(f"LLAMA_STACK_ENDPOINT: {LLAMA_STACK_ENDPOINT}")

client = LlamaStackClient(
    base_url=os.getenv("LLAMA_STACK_SERVER")
)

shield_id = "content_safety"
client.shields.register(shield_id=shield_id, provider_shield_id="Llama-Guard-3-8B")


