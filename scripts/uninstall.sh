#!/usr/bin/env bash
#
# uninstall.sh — reverte a instalação do pacote Kanban.
#
# Uso:
#   ./scripts/uninstall.sh /caminho/para/o/chatwoot [--target vanilla|fazer-ai]
#
# O que faz:
#   1. Reverte os patches de integração (ordem inversa).
#   2. Remove os arquivos do overlay.
#   3. Lembra de reverter as migrations manualmente (destrutivo em dados).

set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-}"
TARGET="vanilla"

shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

err() { echo "ERRO: $*" >&2; exit 1; }
info() { echo "==> $*"; }

[ -n "$TARGET_DIR" ] || err "Informe o caminho do Chatwoot."
[ -d "$TARGET_DIR" ] || err "Diretório não existe: $TARGET_DIR"

# ---- 1) reverter patches (common + target), em ordem inversa ----
reverse_patches() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local reverted=0
  # ordem inversa para desfazer com segurança
  for p in $(ls "$dir"/*.patch 2>/dev/null | sort -r); do
    if git -C "$TARGET_DIR" apply --reverse --check "$p" 2>/dev/null; then
      git -C "$TARGET_DIR" apply --reverse "$p"
      reverted=$((reverted+1))
    else
      echo "   (não aplicado/ignorando) $(basename "$p")"
    fi
  done
  info "Patches revertidos de $(basename "$dir"): $reverted"
}

info "Revertendo patches..."
reverse_patches "$PKG_DIR/patches/$TARGET"
reverse_patches "$PKG_DIR/patches/common"

# ---- 2) remover arquivos do overlay ----
info "Removendo arquivos do overlay..."
( cd "$PKG_DIR/overlay" && find . -type f -print0 | while IFS= read -r -d '' rel; do
    dest="$TARGET_DIR/${rel#./}"
    [ -f "$dest" ] && rm -f "$dest"
  done )
# limpar diretórios vazios deixados pelo overlay (best-effort, só kanban_*)
find "$TARGET_DIR/app" -type d -empty -name "*kanban*" -delete 2>/dev/null || true

cat <<EOF

Arquivos removidos e patches revertidos.

ATENÇÃO (manual, destrutivo): as migrations do Kanban NÃO foram revertidas.
Para remover as tabelas kanban_* e conversation_kanban_states, faça rollback
das migrations correspondentes com cuidado (há perda de dados):

  bundle exec rails db:rollback STEP=<n>

Confira as migrations em: overlay/db/migrate/*kanban*
EOF
