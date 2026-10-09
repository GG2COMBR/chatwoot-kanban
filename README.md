# chatwoot-kanban

Kanban de vendas (funil) nativo para o Chatwoot, distribuído como um pacote
instalável sobre uma árvore de código do Chatwoot — sem fork, sem reescrever o
core. O objetivo é ser *plug-and-play*: você aplica o pacote, roda as migrations
e o Kanban aparece integrado ao dashboard.

## O que inclui

- **Boards (funis)** com estágios e cards por drag-and-drop.
- **Cards** a partir de conversas ou manuais; vínculo conversa↔board sem
  duplicar entidades do core.
- **Won/Lost** com motivos, prioridade, SLA por estágio, agendamento.
- **Campos personalizados** por funil e **produtos** por card.
- **Automações** próprias do Kanban (regras, gatilhos, logs).
- **Relatórios** de funil: conversão, won/lost, tempo por estágio, por agente,
  por produto.
- **Entry rules** por inbox; membros e visibilidade por board.

## Compatibilidade

| Alvo | Versão | Status |
| :-- | :-- | :-- |
| Chatwoot CE (vanilla) | v4.18.x | validado estruturalmente |
| fork fazer-ai | v4.18.x | em preparação (`patches/fazer-ai`) |

Os patches de integração são sensíveis à versão. Use a versão homologada em
`VERSION_COMPAT`. Em versões diferentes, o `install.sh` aborta com mensagem
clara (não corrompe a árvore).

## Instalação

Pré-requisitos: uma árvore de código do Chatwoot (git), árvore limpa (para
permitir rollback).

```bash
# a partir da raiz deste repositório
./scripts/install.sh /caminho/para/o/chatwoot --target vanilla
```

O script:
1. valida a versão do Chatwoot alvo;
2. copia os arquivos novos (`overlay/`);
3. aplica os patches de integração (`patches/common` + `patches/<target>`).

Depois, no ambiente do Chatwoot:

```bash
bundle exec rails db:migrate     # cria as tabelas kanban_*
# dev: o Vite recompila ao subir | prod: rake assets:precompile
# reinicie rails + sidekiq
```

O menu **Kanban** aparece na barra lateral.

## Desinstalação

```bash
./scripts/uninstall.sh /caminho/para/o/chatwoot --target vanilla
```

Reverte os patches e remove os arquivos do overlay. As migrations **não** são
revertidas automaticamente (há perda de dados) — faça o rollback manualmente se
desejar remover as tabelas.

## Arquitetura do pacote

Consulte o documento completo em **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** para entender a **Pirâmide de Extensibilidade** e as regras de desenvolvimento para novos contribuidores.

```
overlay/      arquivos NOVOS copiados as-is (models, controllers, migrations, front, initializers)
patches/
  common/     patches cirúrgicos e estritamente aditivos compartilhados
  fazer-ai/   edições específicas do fork fazer-ai
  vanilla/    edições específicas do Chatwoot CE puro
scripts/      install.sh, uninstall.sh, test-package.sh, run-specs.sh, reconcile_migrations.rb
docs/         diretrizes arquiteturais e guias para contribuidores
analysis/     documentos e especificações de referência
```

### Desenvolvimento & Pre-commit Hooks

Para configurar o ambiente de desenvolvimento e ativar a validação automática em cada `git commit`:

```bash
./scripts/setup-dev.sh
```

Isso ativa os hooks nativos versionados em `.githooks/pre-commit`, garantindo que:
- Todos os arquivos Ruby tenham sintaxe válida;
- Todos os patches e o `MANIFEST.txt` estejam sincronizados e integros;
- Nenhuma contaminação ou dependência oculta de forks seja introduzida;
- A regra de ouro de patches estritamente aditivos seja respeitada.

Para rodar a validação manualmente a qualquer momento:

```bash
./scripts/test-package.sh
```

## Estado atual

- **Fase A (Board Principal):** 100% concluída e validada em Chatwoot v4.18 (banco, migrations, build Vite e telas de funil/cards funcionais).
- **Governança & Extensibilidade:** Arquitetura limpa estabelecida priorizando *Overlay First* e *Rails Initializers* para manter o core imune a conflitos de atualização.


## Créditos e licença

Baseado em trabalho de Kanban para Chatwoot da comunidade e no próprio Chatwoot,
ambos sob licença MIT. Os avisos de copyright originais são preservados.
Distribuído sob **MIT** — veja [LICENSE](LICENSE).
