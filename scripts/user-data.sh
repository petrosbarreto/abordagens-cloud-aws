#!/bin/bash
# Lab 1 — cole este conteúdo em "User data" ao criar a instância EC2.
# Repositório: https://github.com/petrosbarreto/abordagens-cloud-aws
dnf install -y python3-pip git
pip3 install flask
git clone https://github.com/petrosbarreto/abordagens-cloud-aws.git /opt/app
cd /opt/app
ABORDAGEM=IaaS PORT=80 \
  nohup python3 application.py \
  > /var/log/app.log 2>&1 &
