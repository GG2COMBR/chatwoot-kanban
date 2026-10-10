# Guia de Desenvolvimento Local

Este guia orienta a preparação do ambiente de desenvolvimento e testes locais para contribuidores do **chatwoot-kanban**.

---

## 1. Pré-requisitos

- Git
- Ruby 3.3+ ou 3.4+
- Node.js 20+ e pnpm
- Docker & Docker Compose (para banco de dados local)

---

## 2. Subindo Serviços de Apoio (PostgreSQL & Redis)

Disponibilizamos um arquivo `docker-compose.dev.yml` na raiz para iniciar instantaneamente o banco de dados e o Redis:

```bash
# Iniciar Postgres e Redis em background
docker compose -f docker-compose.dev.yml up -d

# Verificar status
docker compose -f docker-compose.dev.yml ps
```

As credenciais padrão configuradas são:
- **PostgreSQL:** Host `localhost`, Porta `5432`, Usuário `postgres`, Senha `password`, Banco `chatwoot_development`.
- **Redis:** Host `localhost`, Porta `6379`.

---

## 3. Preparando o Ambiente e Ativando Hooks

Na raiz do repositório `chatwoot-kanban`, configure os hooks nativos de validação:

```bash
./scripts/setup-dev.sh
```

Isso garante que todo `git commit` valide automaticamente:
- Sintaxe Ruby em todos os arquivos de `overlay/` e `scripts/`;
- Integridade de patches e manifesto `MANIFEST.txt`;
- Paridade de chaves de internacionalização entre `pt_BR` e `en`;
- Conformidade com a Regra de Ouro (patches puramente aditivos).

Para rodar a verificação manualmente a qualquer momento:
```bash
./scripts/test-package.sh
```

---

## 4. Instalando o Kanban sobre um Chatwoot Local

Clone uma árvore de código limpa do Chatwoot CE (v4.18.x) e instale o pacote:

```bash
# A partir da raiz do chatwoot-kanban
./scripts/install.sh /caminho/para/o/chatwoot --target vanilla
```

No diretório do Chatwoot alvo:
```bash
# Instalar dependências npm do Kanban
pnpm add chart.js@~4.4.4 vue-chartjs@5.3.1

# Rodar as migrations do Kanban
bundle exec rails db:migrate

# Iniciar o servidor de desenvolvimento
bin/dev
```

Para reverter a instalação a qualquer momento:
```bash
./scripts/uninstall.sh /caminho/para/o/chatwoot --target vanilla
```
