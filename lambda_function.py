"""Lab 4 — Serverless (Refactor).

O mesmo comportamento da API Flask, reescrito no modelo nativo do Lambda:
não há servidor nem processo esperando conexões, só um handler chamado a
cada requisição do API Gateway (HTTP API). Por isso não existe "host" —
no lugar dele devolvemos o request_id de cada invocação.
"""
import json


def lambda_handler(event, context):
    body = {
        "abordagem": "Serverless",
        "request_id": context.aws_request_id,
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
