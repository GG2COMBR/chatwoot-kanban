# Changelog

Todas as alterações notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [1.0.1] - 2026-10-09

### 🚀 Melhorias e Governança
- **Paridade 100% de Internacionalização (i18n):** Sincronizadas todas as 48 chaves faltantes no inglês (`en/kanban.json`) e adicionado validador de paridade executado no CI e no hook pré-commit. (Fixes #1)
- **Specs Unitárias & Factories RSpec:** Cobertura de testes unitários para models de catálogo e funil (`KanbanProduct`, `KanbanProductSource`, `KanbanReason`, `KanbanCardProduct`). (Fixes #2)
- **Governança & Segurança (CI):** Configurado Dependabot para monitoramento semanal de dependências npm/actions e adicionada a política de reporte de vulnerabilidades `SECURITY.md`. (Fixes #3)
- **Performance & AbortController:** Suporte a cancelamento transparente de requisições de listagem de cartões via `AbortController` (`signal`) na API client. (Fixes #4)
- **Rollback Atômico na Instalação:** Adicionado handler com `trap` no `scripts/install.sh` garantindo reversão automática e restauração limpa da árvore caso ocorra erro no meio da instalação. (Fixes #5)
- **Ambiente de Teste Local Desacoplado:** Disponibilizado `docker-compose.dev.yml` com Postgres e Redis e novo manual em `docs/DEVELOPMENT.md`. (Fixes #6)

---

## [1.0.0] - 2026-10-09

### 🚀 Adicionado
- **Módulo Kanban CRM Nativo:** Integração completa ao dashboard do Chatwoot através de overlay desacoplado e patches cirúrgicos aditivos, eliminando a necessidade de forks permanentes.
- **Arquitetura Multi-tenant Estrita:** Controle de acesso granular por conta via feature flags nativas do Chatwoot (`kanban` e `kanban_products`). Contas sem flag ativa têm menus ocultos e APIs bloqueadas com status `403 Forbidden`.
- **Funis e Gestão de Oportunidades:** Suporte a múltiplos funis (boards), estágios customizáveis, drag-and-drop de cards, ordenação inteligente e vínculo biunívoco com conversas do Chatwoot.
- **Catálogo de Produtos Nativo:** Módulo interno de produtos (`KanbanProduct`) e fontes de dados (`KanbanProductSource`) por conta, permitindo cotação e cálculo financeiro direto no card de oportunidade.
- **Suporte a Promoções "De / Por":** Campos `regular_price` e `sale_price` com cálculo de desconto percentual, badge visual "PROMOÇÃO" e preço riscado na busca de produtos.
- **Importador CSV Inteligente:** Detecção automática de delimitadores (`;`, `,`, `\t`), parsing de moedas (`89.90 BRL`, `R$ 49,90`, `$ 49.99`), remoção transparente de UTF-8 BOM do Excel e suporte a categorias de produtos.
- **Integração Google Merchant XML:** Sincronização periódica automatizada via background jobs com feeds padrão Google Shopping.
- **Gestão de Motivos de Ganho e Perda:** Cadastro customizado de motivos por funil com validação opcional de preenchimento obrigatório ao marcar leads como perdidos.
- **Toggles de Exibição por Funil:** Opções `enable_products` e `show_monetary_values` para alternar a exibição de produtos e valores em R$ entre funis comerciais e funis de suporte/helpdesk.
- **Motor de Automações do Kanban:** 7 regras operacionais suportadas (`move_to_stage`, `set_priority`, `add_label`, `remove_label`, `set_due_at`, `create_note`, `assign_agents`, `mark_as_lost`).
- **Auditoria e Logs em Tempo Real:** Registro persistente de execuções (`KanbanAutomationLog`) com interface para acompanhamento de disparos, testes simulados (*Dry Run*) e diagnósticos.
- **Documentação Consolidada:** Guias detalhados com diagramas de sequência em `docs/USER_GUIDE.md`, princípios em `docs/ARCHITECTURE.md` e runbook em `docs/PRODUCTION_PREFLIGHT.md`.
- **Licenciamento PolyForm Noncommercial 1.0.0:** Proteção jurídica contra revenda/redistribuição comercial indevida com canais diretos de suporte especializado e implantação profissional.

### 🔄 Modificado
- Higienização completa de documentações legadas e rascunhos de planejamento obsoletos (`PLANO.md`, `analysis/`, `overlay/docs/`).
- Atualização e otimização dos cards do funil (`KanbanConversationCard.vue`), removendo ícones duplicados de canal.

### 🐛 Corrigido
- Resolução de colisões de timestamp de migrations herdadas da versão v4.14 para compatibilidade com o Chatwoot v4.18.
- Tratamento de parâmetros ausentes em requisições de criação de fontes de produto (`kanban_product_source`).
