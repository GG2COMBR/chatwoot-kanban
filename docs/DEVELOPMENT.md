# Guia de Desenvolvimento & Ambiente Local (Docker & Bare Metal)

Este guia orienta a preparação do ambiente, execução local completa com Docker (ou local bare-metal) e o ciclo 100% plug-and-play do **chatwoot-kanban**.

---

## 1. Pré-requisitos

- Git
- Docker & Docker Compose (para execução em containers)
- Node.js 20+ e Ruby 3.3+ (apenas se for rodar fora do Docker)

---

## 2. Rodando o Chatwoot com Docker Compose Local

O Chatwoot oficial disponibiliza uma stack Docker de desenvolvimento. No entanto, dependendo da versão (ex: v4.18 com Vite 6 e PostgreSQL 16), o Docker Compose nativo exige pequenas configurações de rede para permitir conexões locais seguras.

### 2.1 Criando o `docker-compose.override.yaml`

No diretório do Chatwoot (ex: `chatwoot-vanilla`), crie um arquivo `docker-compose.override.yaml` (este arquivo é ignorado e não altera o git do Chatwoot):

```yaml
services:
  postgres:
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
  rails:
    environment:
      VITE_RUBY_HOST: vite
  vite:
    environment:
      VITE_RUBY_HOST: 0.0.0.0
      __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS: "vite"
```

> **Por que essas variáveis são necessárias?**
> 1. `POSTGRES_HOST_AUTH_METHOD: trust`: Permite a conexão local ao container PostgreSQL sem conflito de senha em dev.
> 2. `VITE_RUBY_HOST: vite`: Informa ao Rails para buscar assets dev no hostname interno do container `vite`.
> 3. `VITE_RUBY_HOST: 0.0.0.0` e `__VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS: "vite"`: O Vite 6 bloqueia por padrão requisições de hosts não reconhecidos (evitando o erro `403 Forbidden: Blocked request. This host ("vite") is not allowed`).

Se desejar garantir que o Git do Chatwoot permaneça 100% limpo, adicione a linha ao `.git/info/exclude`:
```bash
echo "docker-compose.override.yaml" >> .git/info/exclude
```

---

## 3. Preparando o Banco Oficial do Chatwoot

No diretório do Chatwoot:

```bash
# 1. Subir serviços base
docker compose up -d postgres redis mailhog

# 2. Aguardar o Postgres ficar pronto e criar o banco limpo
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

---

## 4. Instalando o Pacote Kanban de Forma Autônoma

No diretório do **`chatwoot-kanban`**, execute o instalador automatizado com a flag `--run-migrations`:

```bash
./scripts/install.sh /caminho/para/chatwoot-vanilla --target vanilla --run-migrations
```

O script executa de forma autônoma e idempotente:
1. Valida a compatibilidade de versão (`VERSION_COMPAT`);
2. Copia todos os novos arquivos do `overlay/`;
3. Aplica os patches aditivos de integração (`patches/common` e `patches/vanilla`);
4. Executa a reconciliação e as migrations no banco de dados via container Rails.

> **Zero dependências npm externas:** O Kanban utiliza exclusivamente os componentes de gráficos nativos do Chatwoot (`shared/components/charts/BarChart.vue` e `@chatwoot/viz`), sem alterar o `package.json` ou requerer `pnpm add`.

---

## 5. Criando Usuário de Acesso e Habilitando Features

Para acessar o Chatwoot e ter acesso imediato ao Kanban:

```bash
docker compose run --rm rails bundle exec rails runner "
account = Account.first || Account.create!(name: 'Acme Corp')
user = User.find_by(email: 'admin@kanban.test') || User.new(email: 'admin@kanban.test', name: 'Admin Test')
user.password = 'Password123!'
user.password_confirmation = 'Password123!'
user.confirmed_at = Time.current
user.save!

AccountUser.find_or_create_by!(account: account, user: user) do |au|
  au.role = :administrator
end

account.enable_features('kanban', 'kanban_products') if account.respond_to?(:enable_features)
account.save!
puts 'Pronto! Acesso admin configurado.'
"
```

---

## 6. Subindo a Aplicação e Acessando

```bash
# Subir os serviços de aplicação
docker compose up -d rails sidekiq vite
```

Acesse no navegador:
- **URL:** [http://localhost:3000/app/login](http://localhost:3000/app/login)
- **E-mail:** `admin@kanban.test`
- **Senha:** `Password123!`
- **Kanban:** [http://localhost:3000/app/accounts/1/kanban](http://localhost:3000/app/accounts/1/kanban) ou pelo menu lateral da aplicação.

---

## 7. Como Limpar e Resetar o Ambiente do Zero (Clean Reset)

Se quiser testar a reinstalação a qualquer momento ou limpar dados de teste:

```bash
# 1. No diretório do chatwoot: parar e apagar containers e volumes
docker compose down -v

# 2. Restaurar o repositório do Chatwoot para o código original
git checkout -- . && git clean -fd

# 3. Recriar os serviços e rodar novamente a partir da seção 3
```

---

## 8. Desinstalando o Kanban

Caso precise apenas reverter a integração do Kanban sem apagar o Chatwoot:

```bash
./scripts/uninstall.sh /caminho/para/chatwoot-vanilla --target vanilla
```
