# Smoke test e plano de continuação

Documento de progresso do porte do Kanban (fonte `pedrohenrique505/chatwoot-kanban`,
base v4.14) para o Chatwoot CE **v4.18** (e depois fazer-ai v4.18).

Atualizado após o primeiro smoke test funcional em ambiente Docker rodando.

## 1. O que já está validado (feito)

### Backend / banco — 100% validado
- `install.sh` aplica overlay + patches de forma reproduzível em árvore limpa.
- As **51 migrations** do Kanban rodam e criam as **17 tabelas** (`kanban_*` +
  `conversation_kanban_states`), com **0 pendências**.
- Sintaxe Ruby OK nos arquivos core alterados.
- `uninstall.sh` reverte patches + remove overlay (git status limpo).

### Frontend — parcialmente validado
- Build do Vite transformou 3733 módulos (avança quase até o fim).
- Ainda falha por patches de integração do front que precisam ser refeitos
  (ver seção 3).

## 2. Bugs reais encontrados e CORRIGIDOS pelo smoke test

Estes não apareceriam na validação estrutural (só com o app rodando):

1. **Colisão de timestamp de migration** (2 casos) — o fork era v4.14; entre
   v4.14 e v4.18 o Chatwoot adicionou migrations com o mesmo timestamp.
   - `20260616120000` (kanban `switch_kanban_cards_to_hard_delete` vs vanilla
     `add_icon_to_teams`) → renomeada para `...120001`.
   - `20260813000000` (kanban `migrate_kanban_stage_colors_to_hex` vs vanilla
     `add_geo_location_to_audits`) → renomeada para `...000001`.
   - Correção aplicada no `overlay/db/migrate/`.

2. **Dependência da extensão `unaccent`** — a migration
   `add_kanban_search_indexes` usa `unaccent()` mas não habilitava a extensão
   (no fork vinha de outra migration não-kanban). Correção: a migration agora
   faz `enable_extension 'unaccent'` (idempotente).

3. **`db:chatwoot_prepare` vs migrations do Kanban** — o fluxo oficial do
   Chatwoot usa `db:schema:load`, que marca como aplicadas as migrations com
   data anterior ao schema. 47 das 51 migrations do Kanban (datas v4.14-era)
   eram marcadas sem rodar, deixando as tabelas sem criar. **Procedimento de
   instalação correto:** após `db:chatwoot_prepare`, remover do
   `schema_migrations` os registros das migrations kanban não executadas e
   rodar `db:migrate` (que então cria as tabelas). *Precisa ser automatizado no
   install.sh — ver seção 4.*

4. **Contaminação de patches com código não-kanban** — os patches foram
   gerados a partir do diff `v4.14 -> branch`, que acumula outras features do
   fork (WAHA, pins, unread counts, embedded, notifications). Impactos:
   - `dashboard.routes.js` importava `./notifications/routes` (inexistente no
     vanilla) → patch refeito só com kanban.
   - 4 patches periféricos (`ConversationItem`, `ContactConversations`,
     `ContactPanel`, `ConversationView`) dependiam da feature "embedded" →
     **removidos** (integração periférica, não essencial ao board).

5. **Arquivos de dependência faltando no overlay** — componentes do board
   importavam arquivos do fork que o filtro por nome "kanban" não pegou.
   Adicionados ao overlay (todos autossuficientes, verificados):
   - `helper/embeddedConversationHistory.js`
   - `composables/useSlaClock.js`
   - `composables/useMessageStatus.js`
   - `components-next/taginput/AgentTagInput.vue`
   - `components-next/message/MessageStatusIndicator.vue`
   - `shared/components/charts/DoughnutChart.vue`

6. **Dependências npm faltando** — `chart.js@~4.4.4` e `vue-chartjs@5.3.1`
   (usadas pelo `KanbanDashboardView.vue`). Não existem no vanilla. Precisam
   ser declaradas pelo pacote e instaladas na instalação — ver seção 4.

## 3. Problema sistêmico identificado (a resolver)

**Patches que REMOVEM código do v4.18.** Como os patches derivam de um diff
entre versões, ~19 deles contêm linhas de remoção que não são do Kanban — em
vários casos isso **reverte features que o v4.18 introduziu** e o fork (v4.14)
não tinha.

Caso confirmado: `settings/automation/constants.js` — o patch remove
`DEFAULT_TRIGGER`, `DELAYED_TRIGGERS`, `DEFAULT_DELAY_MINUTES` etc., que o
vanilla v4.18 usa (quebra `AutomationWaitCondition.vue`, um componente do
próprio v4.18).

### Patches com remoções não-kanban (precisam de revisão manual)
automation_rules_controller.rb, macros_controller.rb, AutomationActionInput.vue,
useMacros.js, useUISettings.js, actionQueryGenerator.js, URLHelper.js,
en/macros.json, pt_BR/automation.json, pt_BR/macros.json,
automation/constants.js, automation/Index.vue, macros/MacroEditor.vue,
busEvents.js, account.rb, automation_rule.rb, macro.rb,
labels/update_service.rb, config/locales/pt_BR.yml.

> A maioria é da feature **"Kanban como ação de automação/macro"** — integração
> avançada, não essencial ao board principal.

### Patches de integração JÁ refeitos à mão (corretos, aditivos, validados no v4.18)
destroy_service.rb, conversation.rb, en/settings.json, pt_BR/settings.json,
config/routes.rb, actionCable.js, Sidebar.vue, dashboard.routes.js.

## 4. Plano de continuação (faseado)

### Fase A — Board principal funcional (escopo enxuto) [✅ CONCLUÍDA]
Objetivo: board Kanban renderizando no v4.18, sem a integração automação-macro.
Resultado do smoke test funcional em Chatwoot CE v4.18 (Docker):
- 16 patches de automação-macro movidos para `patches/_deferred_automation_macro/`
  (Fase B). Restam 31 patches `common`, todos estritamente aditivos.
- Patches corrigidos para serem aditivos (não remover código do v4.18):
  URLHelper.js, account.rb, busEvents.js, useUISettings.js, config/locales/pt_BR.yml.
- Dependências npm declaradas em `npm-dependencies.txt` (chart.js, vue-chartjs);
  `install.sh` passou a listá-las/instruir instalação.
- Reconciliação de migrations automatizada em `scripts/reconcile_migrations.rb`.
- **Build do Vite: ✅ `built in 47.75s` (5217 módulos), sem erros.**
- **HTTP 200; home renderiza sem erro de manifest.**
- **55 rotas da API Kanban montadas no Rails.**
- **End-to-end OK:** criado board + 2 estágios + card, card movido entre
  estágios, contabilizado no board.
- Validação reproduzível: `install.sh` aplica 31/31 patches em árvore v4.18
  limpa; sintaxe Ruby/YAML OK; 51 migrations criam 17 tabelas.


### Fase B — Integração automação-macro (completo)
Refazer manualmente os ~19 patches da seção 3, estritamente **aditivos** sobre
o v4.18 (nunca remover código do v4.18). Validar cada um com build + specs.

### Fase C — Alvo fazer-ai v4.18
Gerar `patches/fazer-ai`: aplicar sobre o fork, resolver os deltas onde o
fazer-ai divergiu do vanilla (ex.: Sidebar próprio). Reaproveita Fase A/B.

### Fase D — Robustez e automação
- CI que instala o pacote num Chatwoot CE v4.18 limpo e roda os specs.
- `install.sh` com manifest de dependências npm e reconciliação de migrations.
- Documentar o procedimento de instalação completo no README.

## 5. Regras aprendidas (para não repetir erros)

- **Patch de integração é SEMPRE aditivo.** Nunca remover linhas que o alvo
  (v4.18) possui. Gerar o patch aplicando a mudança sobre o arquivo do v4.18,
  não a partir do diff entre versões.
- **Validar imports do overlay** contra o alvo antes de confiar (um arquivo
  novo pode importar algo que só existe no fork).
- **Smoke test funcional é obrigatório** antes de declarar "pronto" — a
  validação estrutural (git apply) não pega colisão de migration, extensão de
  banco, import quebrado nem dependência npm.
- **Migrations de add-on** não convivem bem com `schema:load`; prever passo de
  reconciliação.

## 6. Estado dos artefatos

- Repo publicado: https://github.com/GG2COMBR/chatwoot-kanban (commit inicial;
  este documento e as correções ainda NÃO commitados).
- Smoke env (temporário): `/tmp/cw-smoke` (Chatwoot CE v4.18 + pacote, Docker up,
  banco migrado). Pode ser descartado quando a Fase A fechar.
- Overlay local já atualizado com as correções de migrations e os 6 arquivos de
  dependência; patches `common` já tiveram 5 removidos (4 embedded + schema.rb).
