# Abordagens em Cloud Computing na AWS

Repositório: https://github.com/petrosbarreto/abordagens-cloud-aws

Material de apoio da aula prática (3h): a **mesma aplicação** implantada de quatro formas na AWS, do maior controle à menor operação.

| Lab | Abordagem | Serviço | Estratégia (7R) | Tempo |
|-----|-----------|---------|-----------------|-------|
| 1 | IaaS | Amazon EC2 | Rehost | 30 min |
| 2 | PaaS | AWS Elastic Beanstalk | Replatform | 25 min |
| 3 | Containers | Amazon ECR + ECS Fargate | Replatform | 30 min |
| 4 | Serverless | AWS Lambda + API Gateway | Refactor | 20 min |

```
.
├── application.py        # API Flask (Labs 1, 2 e 3)
├── requirements.txt      # flask
├── Dockerfile            # imagem do Lab 3
├── lambda_function.py    # handler do Lab 4
├── dist/
│   └── lab2-beanstalk.zip # pacote pronto do Lab 2
└── scripts/
    ├── user-data.sh      # Lab 1 — cole em "User data" da EC2
    └── build-push.sh     # Lab 3 — build e push da imagem para o ECR
```

A resposta de cada implantação é um JSON com o campo `abordagem` e o `host` que atendeu a requisição:

```json
{"abordagem": "IaaS", "host": "ip-172-31-10-20.ec2.internal"}
```

---

## Antes de começar — AWS Academy Learner Lab

1. No curso do AWS Academy, abra o módulo **Learner Lab** → **Start Lab** → aguarde o indicador **verde** → clique em **AWS**.
2. Use a região **us-east-1 (N. Virginia)**.
3. **Não crie roles IAM** — o Learner Lab não permite. Use sempre as que já existem:
   - `LabRole` — service role, task role, execution role da Lambda
   - `LabInstanceProfile` — instance profile de EC2
   - `vockey` — key pair
4. Os créditos são limitados: use instâncias pequenas (`t3.micro`) e faça a **limpeza** ao final.

Em dupla: uma pessoa executa, a outra cronometra e anota. Troquem a cada lab.

### O que anotar em cada lab

- Tempo até a primeira resposta (min)
- Quantos cliques/comandos foram necessários
- O que você teria que manter se isso fosse para produção

---

## Lab 1 — IaaS com EC2 (Rehost)

1. EC2 → **Launch instance**
   - Nome: `lab1-iaas`
   - AMI: **Amazon Linux 2023**
   - Tipo: **t3.micro**
   - Key pair: **vockey**
2. Network settings → security group com:
   - **HTTP (80)** de `0.0.0.0/0`
   - **SSH (22)** de `0.0.0.0/0` — só no laboratório: o EC2 Instance Connect pelo navegador (usado no Lab 3) conecta a partir de endereços da AWS. Em produção, restrinja ao prefix list do EC2 Instance Connect ou use Session Manager.
3. Advanced details:
   - IAM instance profile: **LabInstanceProfile**
   - User data: conteúdo de [`scripts/user-data.sh`](scripts/user-data.sh), (já aponta para este repositório)
4. **Launch instance** → aguarde os *status checks* → abra `http://<IP público>` (http, não https).

**Não termine esta instância** — ela será a máquina de build do Lab 3.

**Discussão:** como você aplicaria um patch de segurança no SO? E se a aplicação cair — quem a reinicia? Como escalaria para 3 máquinas atrás de um único endereço?

<details><summary>Não respondeu?</summary>

- Security group sem a porta 80 liberada.
- Abriu `https://` em vez de `http://`.
- Erro no user data: conecte via **EC2 Instance Connect** e veja `/var/log/cloud-init-output.log` e `/var/log/app.log`.
</details>

---

## Lab 2 — PaaS com Elastic Beanstalk (Replatform)

1. Baixe o pacote pronto [`dist/lab2-beanstalk.zip`](https://github.com/petrosbarreto/abordagens-cloud-aws/raw/main/dist/lab2-beanstalk.zip) — ele tem `application.py` e `requirements.txt` **na raiz**. Para gerar de novo:
   ```bash
   zip dist/lab2-beanstalk.zip application.py requirements.txt
   ```
2. Elastic Beanstalk → **Create application** → **Web server environment**
   - Platform: **Python**
   - Application code: **Upload your code** → `lab2-beanstalk.zip`, version label `v1`
   - Presets: **Single instance**
3. Configure service access:
   - Service role: **Use an existing service role** → **LabRole**
   - EC2 key pair: **vockey**
   - EC2 instance profile: **LabInstanceProfile**
4. Em *Updates, monitoring and logging* → **Environment properties**: `ABORDAGEM` = `PaaS`
5. **Submit** → aguarde o status **Ok** (5–10 min) → abra o domínio do ambiente.

**Investigue enquanto espera:** abra o **CloudFormation** e encontre a stack `awseb-…`. Quais recursos o Beanstalk criou por você?

**Discussão:** o que muda para publicar a versão 2? E se você precisar instalar um pacote no SO?

---

## Lab 3 — Containers com ECR + ECS Fargate (Replatform)

### Parte A — Build e push da imagem (na EC2 do Lab 1)

1. EC2 → selecione `lab1-iaas` → **Connect** → **EC2 Instance Connect**.
2. Rode:
   ```bash
   bash /opt/app/scripts/build-push.sh
   ```
3. Copie o **URI da imagem** impresso no final (`<conta>.dkr.ecr.us-east-1.amazonaws.com/abordagens:v1`).

O script instala o Docker, cria o repositório `abordagens` no ECR (se não existir), faz login, build e push. A instância usa o `LabInstanceProfile`, que já tem permissão de ECR.

### Parte B — Serviço no ECS Fargate

1. ECS → Clusters → **Create cluster**: `lab3-cluster`, infraestrutura **AWS Fargate (serverless)**.
2. Task definitions → **Create new task definition**
   - Launch type: **AWS Fargate**; 0.5 vCPU / 1 GB
   - Task role: **LabRole** · Task execution role: **LabRole**
   - Container: nome `app`, imagem = URI da parte A, porta **80**
   - Environment variable: `ABORDAGEM` = `Containers`
3. No cluster → Services → **Create**
   - Task definition: a que você criou; desired tasks: **1**
   - Networking: VPC default, **subnets públicas**, **Public IP ligado**
   - Security group: novo, liberando **TCP 80** de `0.0.0.0/0`
4. Aba **Tasks** → abra a tarefa → copie o **Public IP** → `http://<IP>`.

**Experimento:** atualize o serviço para **3 tarefas**. Cada tarefa tem seu próprio IP e `host`. O que faltaria para ter um único endereço? *(Dica: Application Load Balancer.)*

**Discussão:** esta mesma imagem rodaria no seu notebook? No EKS? Em outro provedor?

<details><summary>Tarefa travada em PENDING ou parando sozinha?</summary>

- Public IP desligado: a tarefa não consegue baixar a imagem do ECR.
- Task execution role vazia: selecione **LabRole**.
- Security group sem a porta 80.
</details>

---

## Lab 4 — Serverless com Lambda + API Gateway (Refactor)

1. Lambda → **Create function** → *Author from scratch*
   - Nome: `lab4-serverless`
   - Runtime: **Python 3.12**
   - Change default execution role → **Use an existing role** → **LabRole**
2. Cole o conteúdo de [`lambda_function.py`](lambda_function.py) → **Deploy**.
3. **Add trigger** → **API Gateway** → *Create a new API* → **HTTP API**, security **Open**.
4. Abra o **API endpoint** mostrado na aba *Configuration → Triggers* e recarregue várias vezes: o `request_id` muda a cada chamada.
5. Aba **Monitor**: veja invocações e duração no CloudWatch. Compare a duração da primeira chamada (cold start) com as seguintes.

**Discussão:** onde está o servidor? O que você paga quando ninguém está chamando a API? Por que o código precisou mudar?

---

## Comparação — preencha com os seus dados

| Critério | IaaS · EC2 | PaaS · Beanstalk | Containers · Fargate | Serverless · Lambda |
|---|---|---|---|---|
| Tempo até responder | __ min | __ min | __ min | __ min |
| Cliques/comandos | | | | |
| Você mantém | SO, runtime, processo, app | App e config da plataforma | Imagem e definição da tarefa | A função |
| Como escala | Você monta ASG + ELB | Auto Scaling do ambiente | Nº de tarefas / Service Auto Scaling | Automático, por requisição |
| Você paga por | Instância ligada | Recursos criados (EC2, ELB…) | vCPU e memória por segundo | Requisições + duração |
| Ocioso custa? | Sim | Sim | Sim, se houver tarefas | Não |
| Estratégia (7R) | Rehost | Replatform | Replatform | Refactor |

---

## Limpeza — na ordem inversa

1. **Lab 4:** excluir a função `lab4-serverless` e a API criada no API Gateway.
2. **Lab 3:** excluir o serviço (ou reduzir para 0 tarefas antes), o cluster `lab3-cluster` e o repositório `abordagens` no ECR.
3. **Lab 2:** Elastic Beanstalk → ambiente → Actions → **Terminate environment** (remove a stack inteira) e depois a aplicação.
4. **Lab 1:** **Terminate** na instância `lab1-iaas`; conferir **Volumes** e **Elastic IPs** soltos.
5. **End Lab** no AWS Academy.

---

## Rodando localmente (opcional)

```bash
pip install -r requirements.txt
ABORDAGEM=Local PORT=8080 python application.py
# http://localhost:8080

docker build -t abordagens .
docker run --rm -p 8080:80 -e ABORDAGEM=Docker abordagens
```

## Referências

- NIST SP 800-145 — *The NIST Definition of Cloud Computing*
- AWS Prescriptive Guidance — estratégias de migração (7Rs)
- AWS — Modelo de responsabilidade compartilhada
- AWS Well-Architected Framework
