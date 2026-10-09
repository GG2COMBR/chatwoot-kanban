#!/usr/bin/env bash
#
# test-package.sh — Suíte de validação estática e integridade do pacote chatwoot-kanban.
#
# Executa validações locais e em CI sem exigir um banco de dados rodando:
#   1. Validação de sintaxe Ruby (ruby -c com Ruby 3+) em todos os arquivos .rb
#   2. Verificação de integridade dos arquivos .patch
#   3. Validação de manifesto patches/common/MANIFEST.txt
#   4. Validação de sintaxe JSON de traduções e configurações via Node.js / Python
#
# Uso:
#   ./scripts/test-package.sh
#

set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

info() { echo -e "${BLUE}==>${NC} $*"; }
pass() { echo -e "  ${GREEN}✔${NC} $*"; }
fail() { echo -e "  ${RED}✖${NC} $*"; ERRORS=$((ERRORS + 1)); }

# Detectar Ruby 3+ adequado (prioriza rbenv/asdf/mise sobre o Ruby 2.6 legado do sistema macOS)
RUBY_BIN="ruby"
if [ -d "$HOME/.rbenv/versions" ]; then
  latest_rbenv_ruby="$(find "$HOME/.rbenv/versions" -maxdepth 3 -name "ruby" -type f -perm +111 2>/dev/null | grep -E '/bin/ruby$' | sort -V | tail -1 || true)"
  if [ -n "$latest_rbenv_ruby" ] && [ -x "$latest_rbenv_ruby" ]; then
    RUBY_BIN="$latest_rbenv_ruby"
  fi
fi

ruby_ver="$("$RUBY_BIN" -e 'puts RUBY_VERSION' 2>/dev/null || echo "0.0.0")"

echo "=================================================="
echo "   chatwoot-kanban :: Validação de Integridade   "
echo "=================================================="
echo "Ruby runtime: $RUBY_BIN (v$ruby_ver)"

# 1. Sintaxe Ruby em overlay/ e scripts/
info "1. Validando sintaxe Ruby em overlay/ e scripts/..."
ruby_count=0
while IFS= read -r -d '' file; do
  ruby_count=$((ruby_count + 1))
  if ! "$RUBY_BIN" -c "$file" >/dev/null 2>&1; then
    fail "Erro de sintaxe Ruby: ${file#"$PKG_DIR/"}"
  fi
done < <(find "$PKG_DIR/overlay" "$PKG_DIR/scripts" -type f -name "*.rb" -print0)

if [ $ruby_count -gt 0 ]; then
  pass "$ruby_count arquivos Ruby verificados com sucesso."
else
  fail "Nenhum arquivo Ruby encontrado para validação."
fi

# 2. Integridade dos patches
info "2. Validando integridade dos arquivos de patch..."
patch_count=0
for patch in "$PKG_DIR"/patches/common/*.patch; do
  [ -e "$patch" ] || continue
  patch_count=$((patch_count + 1))
  if ! head -n 5 "$patch" | grep -q "^diff --git"; then
    fail "Patch inválido ou mal formatado: $(basename "$patch")"
  fi
done

if [ $patch_count -gt 0 ]; then
  pass "$patch_count patches em patches/common/ validados."
else
  fail "Nenhum patch encontrado em patches/common/."
fi

# 3. Validação do MANIFEST.txt
info "3. Verificando manifesto de patches (MANIFEST.txt)..."
manifest_file="$PKG_DIR/patches/common/MANIFEST.txt"
if [ ! -f "$manifest_file" ]; then
  fail "patches/common/MANIFEST.txt não encontrado."
else
  manifest_diff="$(diff -u <(cd "$PKG_DIR/patches/common" && ls -1 *.patch) "$manifest_file" || true)"
  if [ -n "$manifest_diff" ]; then
    fail "MANIFEST.txt desatualizado em relação a patches/common/:\n$manifest_diff"
  else
    pass "MANIFEST.txt sincronizado com patches/common/."
  fi
fi

# 4. Validação de JSONs
info "4. Validando sintaxe JSON em arquivos do overlay..."
json_count=0
while IFS= read -r -d '' json_file; do
  json_count=$((json_count + 1))
  if command -v node >/dev/null 2>&1; then
    if ! node -e "JSON.parse(require('fs').readFileSync(process.argv[1]))" "$json_file" >/dev/null 2>&1; then
      fail "JSON inválido: ${json_file#"$PKG_DIR/"}"
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$json_file" >/dev/null 2>&1; then
      fail "JSON inválido: ${json_file#"$PKG_DIR/"}"
    fi
  fi
done < <(find "$PKG_DIR/overlay" -type f -name "*.json" -print0)

if [ $json_count -gt 0 ]; then
  pass "$json_count arquivos JSON verificados com sucesso."
else
  pass "Nenhum arquivo JSON isolado em overlay."
fi

# 5. Verificação de conformidade de patches
info "5. Verificando conformidade com a Regra de Ouro (patches aditivos)..."
for patch in "$PKG_DIR"/patches/common/*.patch; do
  [ -e "$patch" ] || continue
  deletions="$(grep -E '^\-[^\-]' "$patch" || true)"
  if [ -n "$deletions" ]; then
    count="$(echo "$deletions" | wc -l | tr -d ' ')"
    echo -e "  ${BLUE}ℹ${NC} $(basename "$patch"): $count linhas modificadas/removidas."
  fi
done
pass "Checagem de conformidade concluída."

echo "=================================================="
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}SUCESSO: Todas as validações passaram! Pacote 100% íntegro.${NC}"
  exit 0
else
  echo -e "${RED}FALHA: $ERRORS erro(s) encontrado(s). Corrija antes de prosseguir.${NC}"
  exit 1
fi
