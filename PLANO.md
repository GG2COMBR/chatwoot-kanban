# Plano — chatwoot-kanban (Kanban de vendas nativo para o fork fazer-ai)

Status: aprovado o rumo (fonte definida); detalhamento de execução pendente.
Objetivo: Kanban **acoplado ao core** (UX integrada), tendo como **base** o
projeto `pedrohenrique505/chatwoot-kanban`, portado para o fork
`fazer-ai v4.18.0`, servindo de ponto de partida para evolução própria.

## 1. Fonte escolhida

- Repo base: https://github.com/pedrohenrique505/chatwoot-kanban
  (branch `feature/kanban-board`)
- Base Chatwoot: **v4.14.0** (seu fork é v4.18.0 → 4 versões de diferença)
- Licença: **MIT (Expat)** — igual ao Chatwoot/fazer-ai. Reuso e redistribuição
  permitidos mantendo avisos de copyright. ✅ compatível.

### Por que esta fonte (vs. módulo LucasZerino, descartado)
| Critério | LucasZerino (descartado) | pedrohenrique505 (escolhido) |
| :-- | :-- | :-- |
| Instalação | patches `sed` cegos | fork nativo, código real |
| Models | 15, duplicam core | 17 próprios, isolados do core |
| Testes | 0 | ~110 specs (models, services, policies, jobs, front) |
| Arquitetura | monolítica | services/jobs/policies/concerns (SRP) |
| Features | kanban + CRM solto | boards, stages, cards, automações próprias, relatórios (conversão, won/lost, SLA, por agente/produto), campos personalizados, motivos de perda/ganho, entry rules por inbox |
| Doc de design | README | SPEC de refatoração + auditoria UI/UX + preflight de produção |
| Base Chatwoot | v4.6 | v4.14 (mais perto do v4.18) |

### Modelo de dados (17 models, isolados)
`kanban_board`, `kanban_stage`, `kanban_card`, `conversation_kanban_state`
(liga conversa↔board sem duplicar entidades do core), `kanban_card_assignee`,
`kanban_card_event`, `kanban_card_note`, `kanban_card_product`,
`kanban_custom_field`, `kanban_card_field_value`, `kanban_reason`,
`kanban_automation_rule`, `kanban_automation_log`, `kanban_board_member`,
`kanban_board_inbox`, `kanban_board_entry_rule`, `kanban_board_entry_rule_inbox`.

> Diferença-chave vs. LucasZerino: as notas/assignees aqui são **escopadas ao
> card** (`kanban_card_note`, `kanban_card_assignee`), não sobrescrevem as do
> Chatwoot. Isso reduz muito a colisão com o fazer-ai.

## 2. Dimensionamento do porte (medido via diff v4.14.0 → branch)

- **337** arquivos NOVOS de Kanban (backend + frontend, sem testes)
  → `analysis/new-files.txt`
- **110** arquivos de teste novos → `analysis/new-test-files.txt`
- **52** pontos de INTEGRAÇÃO no core (arquivos existentes do Chatwoot que o
  projeto edita p/ plugar o Kanban) → `analysis/core-integration-files.txt`

### Temas dos 52 pontos de integração
- **Models core:** `account.rb`, `conversation.rb`, `automation_rule.rb`,
  `macro.rb` (associações `has_many :kanban_*`).
- **Automação/Macros:** Kanban como ação de automação e macro
  (`action_service.rb`, controllers e UI de automação/macros).
- **Realtime:** `action_cable_listener.rb`, `async_dispatcher.rb`,
  `actionCable.js`, `busEvents.js`, `lib/events/types.rb`.
- **Labels:** `labels/destroy_service.rb`, `update_service.rb` (cards usam labels).
- **Front:** `Sidebar.vue`, `dashboard.routes.js`, `store/index.js`,
  `mutation-types.js`, `ConversationView.vue`, `ContactPanel.vue`, i18n (en+pt_BR).
- **Infra:** `config/routes.rb`, `db/schema.rb`, `schema_dumper.rb`.

> Risco concentrado: os pontos que o **fazer-ai também já alterou** sobre o
> Chatwoot base (ex.: `Sidebar.vue`, `conversation.rb`, `account.rb`,
> `dashboard.routes.js`). Nesses, o patch do v4.14 não aplica limpo no v4.18 e
> exige merge manual. Essa é a maior parte do esforço real.

## 3. Estratégia de porte

Fork-base é v4.14; alvo é v4.18. Não dá para aplicar o diff bruto. Abordagem:

1. **Overlay (337 novos):** copiar as-is para o fazer-ai. Baixo risco — são
   arquivos que não existem no fork. Validar só imports/APIs Vue que mudaram
   entre v4.14 e v4.18.
2. **Patches de integração (52):** reescritos como `.patch` git aplicáveis ao
   **v4.18 do fazer-ai**, não ao v4.14. Processo empírico: aplicar sobre uma
   cópia do fazer-ai, resolver conflito a conflito, gerar o diff final.
   - Separar `common/` (aplica em qualquer Chatwoot) de `fazer-ai/` (específico).
3. **Migrations (51):** copiar e rodar `db:migrate` incremental. Validar que não
   colidem com tabelas do fazer-ai (nenhuma tabela `kanban_*` existe no fork → OK).
4. **Testes (110):** trazer junto. São a rede de segurança para validar o porte.

## 4. Arquitetura do repositório `gg2combr/chatwoot-kanban`

```
chatwoot-kanban/
├── PLANO.md                      # este documento
├── COMPATIBILITY.md              # matriz: versões suportadas, o que o fork já tem
├── LICENSE                       # MIT, preservando copyright Chatwoot Inc. + GG2
├── VERSION_COMPAT                # fazer-ai v4.18.0 (homologado)
├── analysis/                     # listas medidas do diff (fonte da verdade do escopo)
│   ├── new-files.txt             # 337
│   ├── new-test-files.txt        # 110
│   └── core-integration-files.txt# 52
├── overlay/                      # os 337 arquivos novos (+ opcional: testes)
├── patches/
│   ├── common/                   # integração válida p/ qualquer Chatwoot
│   ├── fazer-ai/                 # integração específica do fork
│   └── vanilla/                  # (futuro) Chatwoot padrão
├── scripts/
│   ├── install.sh                # detecta alvo + versão, copia overlay, git apply, migrate
│   └── uninstall.sh              # reverte patches, remove overlay, rollback migrations
└── .github/workflows/ci.yml      # aplica contra a tag do fork em container limpo
```

Princípios (mantidos do desenho anterior):
- Overlay (novo) separado de patches (edição em existente).
- Patches como `.patch` git com `git apply --check` (falha explícita, não corrompe).
- Trava de versão no `install.sh`.
- `uninstall.sh` real → reversibilidade.
- CI valida instalabilidade contra `v4.18.0-fazer-ai.126`.

## 5. Fases de execução

- **Fase 0 — Decisões (agora):** escopo (completo vs. núcleo), repo privado/público,
  trazer testes no overlay (recomendado: sim).
- **Fase 1 — Overlay:** copiar os 337 (+testes) do `/tmp/cw-kanban-src` para
  `overlay/`, espelhando a árvore. Entregável: overlay completo versionado.
- **Fase 2 — Patches de integração:** sobre cópia do fazer-ai, aplicar overlay e
  resolver os 52 pontos; gerar `.patch` por arquivo; classificar common/fazer-ai.
  Prioridade: resolver primeiro os que o fazer-ai também alterou.
- **Fase 3 — Scripts + CI + docs:** install/uninstall idempotentes, VERSION_COMPAT,
  COMPATIBILITY.md, workflow.
- **Fase 4 — Validação:** instalar numa cópia limpa do fazer-ai, Docker up,
  `db:migrate`, build Vite, rodar os specs de Kanban, smoke test do board.
  Depois `uninstall` e confirmar reversão.
- **Fase 5 — Publicação:** criar `gg2combr/chatwoot-kanban`, commit inicial, push.

## 6. Riscos
- **Gap v4.14 → v4.18 no front:** componentes Vue podem usar APIs/imports que
  mudaram em 4 versões. Mitigação: validar build do Vite após overlay.
- **Pontos core duplamente modificados (fork + kanban):** merge manual. É o item
  de maior esforço; concentrar atenção aqui.
- **Automação/Realtime:** o fazer-ai estende essas áreas (conector WhatsApp, chat
  interno). Conferir que os patches de automação/actioncable do Kanban não
  conflitam com extensões do fork.
- **`db/schema.rb`:** não portar o schema do v4.14; deixar o `db:migrate` do
  fazer-ai regenerar a partir das migrations.

## 7. Decisões pendentes (Fase 0)
1. Escopo: trazer o Kanban **completo** (automações + relatórios + campos custom +
   produtos) ou só o **núcleo** (board/stages/cards/drag-drop) primeiro?
   Recomendação: completo — o valor está nos relatórios de funil e won/lost.
2. Trazer os 110 testes no overlay? Recomendação: **sim** (rede de segurança).
3. Repo `gg2combr/chatwoot-kanban`: privado ou público? (base MIT permite ambos)

## 8. Estado atual (feito, não-destrutivo)
- Material do módulo LucasZerino removido.
- Fork base clonado em `/tmp/cw-kanban-src` (branch kanban + tag upstream v4.14.0).
- Diff medido; listas salvas em `analysis/`.
- Estrutura do repo recriada em `~/www/chatwoot-kanban/`.
- Nada tocado no fork fazer-ai rodando.
