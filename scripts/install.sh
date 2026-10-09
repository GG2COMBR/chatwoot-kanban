#!/usr/bin/env bash
#
# install.sh — instala o pacote Kanban sobre uma árvore do Chatwoot.
#
# Uso:
#   ./scripts/install.sh /caminho/para/o/chatwoot [--target vanilla|fazer-ai]
#
# O que faz (idempotente):
#   1. Valida a versão do Chatwoot alvo contra VERSION_COMPAT.
#   2. Copia os arquivos novos (overlay/) para o alvo.
#   3. Aplica os patches de integração (patches/common + patches/<target>).
#   4. Deixa pronto para rodar as migrations (não executa db:migrate sozinho).
#
# Não executa migrations nem builda assets — isso é responsabilidade do
# operador (ambiente Docker/local varia). Ao final, imprime os próximos passos.

set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-}"
TARGET="vanilla"

# ---- args ----
shift || true
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done

err() { echo "ERRO: $*" >&2; exit 1; }
info() { echo "==> $*"; }

[ -n "$TARGET_DIR" ] || err "Informe o caminho do Chatwoot. Uso: ./scripts/install.sh <caminho> [--target vanilla|fazer-ai]"
[ -d "$TARGET_DIR" ] || err "Diretório não existe: $TARGET_DIR"
[ -f "$TARGET_DIR/VERSION_CW" ] || err "Não parece um Chatwoot (VERSION_CW ausente): $TARGET_DIR"

# ---- validação de versão ----
CW_VERSION="$(tr -d '[:space:]' < "$TARGET_DIR/VERSION_CW")"
info "Chatwoot alvo: v$CW_VERSION (target=$TARGET)"

compat_line="$(grep -E "^${TARGET}=" "$PKG_DIR/VERSION_COMPAT" || true)"
[ -n "$compat_line" ] || err "Target '$TARGET' não está em VERSION_COMPAT."
range="${compat_line#*=}"; min="${range%%..*}"; max="${range##*..}"
# comparação simples por ordenação de versão
lowest="$(printf '%s\n%s\n' "$min" "$CW_VERSION" | sort -V | head -1)"
highest="$(printf '%s\n%s\n' "$max" "$CW_VERSION" | sort -V | tail -1)"
if [ "$lowest" != "$min" ] || [ "$highest" != "$max" ]; then
  err "Versão v$CW_VERSION fora do intervalo homologado para '$TARGET' ($min..$max)."
fi

# ---- pré-condição: árvore git limpa (para permitir rollback) ----
if git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$TARGET_DIR" diff --quiet || ! git -C "$TARGET_DIR" diff --cached --quiet; then
    err "A árvore do Chatwoot tem alterações não commitadas. Commit/stash antes de instalar (para permitir rollback)."
  fi
fi

# ---- 1) overlay ----
info "Copiando overlay (arquivos novos)..."
( cd "$PKG_DIR/overlay" && find . -type f -print0 | while IFS= read -r -d '' rel; do
    dest="$TARGET_DIR/${rel#./}"
    mkdir -p "$(dirname "$dest")"
    cp "$rel" "$dest"
  done )

# ---- 2) patches ----
apply_patches() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  local applied=0
  for p in "$dir"/*.patch; do
    [ -e "$p" ] || continue
    if git -C "$TARGET_DIR" apply --check "$p" 2>/dev/null; then
      git -C "$TARGET_DIR" apply "$p"
      applied=$((applied+1))
    elif git -C "$TARGET_DIR" apply --reverse --check "$p" 2>/dev/null; then
      echo "   (já aplicado, pulando) $(basename "$p")"
    else
      err "Patch não aplica: $(basename "$p"). O alvo pode ter divergido; use --target correto ou gere patches para esta versão."
    fi
  done
  info "Patches aplicados de $(basename "$dir"): $applied"
}

info "Aplicando patches de integração..."
apply_patches "$PKG_DIR/patches/common"
apply_patches "$PKG_DIR/patches/$TARGET"

# ---- 3) dependências npm ----
NPM_DEPS_FILE="$PKG_DIR/npm-dependencies.txt"
if [ -f "$NPM_DEPS_FILE" ]; then
  deps="$(grep -vE '^\s*#|^\s*$' "$NPM_DEPS_FILE" | tr '\n' ' ')"
  if [ -n "$deps" ]; then
    info "Dependências npm a garantir: $deps"
    echo "   (rode no ambiente do Chatwoot, se ainda não presentes:)"
    echo "     pnpm add $deps"
  fi
fi

cat <<EOF

Instalação de arquivos concluída. Próximos passos (no ambiente do Chatwoot):

  1) Dependências npm (se o passo acima listou):  pnpm add <deps>
  2) Migrations do Kanban. ATENÇÃO: se o banco foi criado via
     'db:chatwoot_prepare' (schema:load), as migrations do Kanban podem ter
     sido marcadas como aplicadas sem rodar. Rode o reconciliador:
         bundle exec rails runner "$(cat "$PKG_DIR/scripts/reconcile_migrations.rb" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')"
     ou, mais simples, copie scripts/reconcile_migrations.rb para o app e rode:
         bundle exec rails runner reconcile_migrations.rb
     Depois:
         bundle exec rails db:migrate
  3) Assets (dev): o Vite recompila ao subir; (prod) rake assets:precompile
  4) Reinicie os serviços (rails + sidekiq).

Para reverter:  ./scripts/uninstall.sh "$TARGET_DIR" --target $TARGET
EOF
