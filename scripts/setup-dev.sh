#!/usr/bin/env bash
# Configuração do ambiente de desenvolvimento local para chatwoot-kanban
set -e

echo "🔧 Configurando ambiente de desenvolvimento do chatwoot-kanban..."

# Ativar pre-commit hooks versionados no repositório
git config core.hooksPath .githooks
echo "✔ Git pre-commit hooks ativados a partir de .githooks/"

# Executar validação de sanidade do pacote
echo "🔍 Validando integridade inicial do pacote..."
./scripts/test-package.sh

echo "🎉 Ambiente configurado com sucesso! Pre-commit ativo para todos os futuros commits."
