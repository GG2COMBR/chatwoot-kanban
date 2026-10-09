#!/usr/bin/env bash
#
# run-specs.sh — Executa a suíte de testes (RSpec e Frontend) do Kanban em uma árvore do Chatwoot.
#
# Uso:
#   ./scripts/run-specs.sh /caminho/para/o/chatwoot [--backend-only|--frontend-only]
#

set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-}"
MODE="all"

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --backend-only) MODE="backend"; shift ;;
    --frontend-only) MODE="frontend"; shift ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

err() { echo "ERRO: $*" >&2; exit 1; }
info() { echo "==> $*"; }

[ -n "$TARGET_DIR" ] || err "Informe o caminho do Chatwoot alvo. Uso: ./scripts/run-specs.sh <caminho> [--backend-only|--frontend-only]"
[ -d "$TARGET_DIR" ] || err "Diretório não existe: $TARGET_DIR"

if [ "$MODE" = "all" ] || [ "$MODE" = "backend" ]; then
  info "Executando suíte RSpec do Kanban no Chatwoot..."
  (
    cd "$TARGET_DIR"
    bundle exec rspec spec/models/kanban_* \
                      spec/controllers/api/v1/accounts/kanban_* \
                      spec/controllers/api/v1/accounts/conversations/kanban_* \
                      spec/services/kanban_* \
                      spec/policies/kanban_* \
                      spec/jobs/kanban_*
  )
fi

if [ "$MODE" = "all" ] || [ "$MODE" = "frontend" ]; then
  info "Executando testes de frontend do Kanban..."
  (
    cd "$TARGET_DIR"
    pnpm test app/javascript/dashboard/routes/dashboard/kanban/specs/ \
              app/javascript/dashboard/routes/dashboard/conversation/Kanban/specs/ \
              app/javascript/dashboard/store/modules/specs/kanbanBoards.spec.js
  )
fi

info "Suíte de testes concluída."
