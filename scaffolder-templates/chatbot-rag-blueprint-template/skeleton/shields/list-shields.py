import os
from llama_stack_client import LlamaStackClient
from rich.pretty import pprint

LLAMA_STACK_ENDPOINT=os.getenv("LLAMA_STACK_ENDPOINT")

print(f"LLAMA_STACK_ENDPOINT: {LLAMA_STACK_ENDPOINT}")

client = LlamaStackClient(
    base_url=os.getenv("LLAMA_STACK_SERVER")
)

for shield in client.shields.list():
    pprint(shield)

