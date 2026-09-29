"""API mínima usada nos quatro labs de "Abordagens em Cloud Computing na AWS".

- Lab 1 (EC2): executada direto com `python3 application.py` (porta 80).
- Lab 2 (Elastic Beanstalk): a plataforma Python procura o objeto `application`
  neste arquivo e o serve com gunicorn — não é preciso Procfile.
- Lab 3 (ECS Fargate): executada dentro do container (ver Dockerfile).

A variável de ambiente ABORDAGEM é a única coisa que muda entre os labs.
"""
import os
import socket

from flask import Flask, jsonify

application = app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(
        abordagem=os.getenv("ABORDAGEM", "?"),
        host=socket.gethostname(),
    )


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "80")))
