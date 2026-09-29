# Imagem base do ECR Public Gallery (evita o limite de pulls anônimos do Docker Hub)
FROM public.ecr.aws/docker/library/python:3.12-slim

WORKDIR /app
COPY . .
RUN pip install --no-cache-dir flask

ENV PORT=80
EXPOSE 80
CMD ["python", "application.py"]
