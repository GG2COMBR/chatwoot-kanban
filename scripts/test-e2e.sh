#!/usr/bin/env bash
# scripts/test-e2e.sh
#
# Executa a suíte de testes E2E do Playwright garantindo que os dados
# de seed estejam previamente aplicados no container Docker do Chatwoot.
#
# Uso:
#   ./scripts/test-e2e.sh [argumentos adicionais do playwright]
#   ./scripts/test-e2e.sh --ui
#   ./scripts/test-e2e.sh e2e/02-boards.spec.ts
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=================================================="
echo "   chatwoot-kanban :: Execução de Testes E2E      "
echo "=================================================="

# 1. Localiza o container ativo do Rails (vanilla ou fazer-ai)
RAILS_CONTAINER=$(docker ps --filter "name=rails" --format "{{.Names}}" | head -n 1)

if [ -z "$RAILS_CONTAINER" ]; then
  echo "ERRO: Nenhum container Rails do Chatwoot ativo no Docker."
  echo "Inicie a stack primeiro (ex: 'docker compose up -d' no diretório do Chatwoot)."
  exit 1
fi

echo "✔ Container detectado: ${RAILS_CONTAINER}"

# 2. Executa o seed idempotente de dados de teste
echo "==> Aplicando dados de seed E2E no Rails..."
docker exec -i "${RAILS_CONTAINER}" bundle exec rails runner - < "${SCRIPT_DIR}/seed-e2e.rb"

# 3. Dispara a suíte de testes Playwright
echo "==> Executando suíte Playwright..."
cd "${ROOT_DIR}"
npx playwright test "$@"
