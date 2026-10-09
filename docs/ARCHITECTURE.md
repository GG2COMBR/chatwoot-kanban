# Arquitetura e Guia de Extensibilidade do chatwoot-kanban

Este documento define as diretrizes arquiteturais, o ciclo de vida e os padrões de desenvolvimento do pacote **chatwoot-kanban**. Todo novo desenvolvedor ou contribuidor deve seguir essas regras para manter a integridade, facilidade de atualização e compatibilidade com novas versões do Chatwoot upstream.

---

## 1. Princípio Fundamental: O Modelo de Pacote Não-Invasivo

O `chatwoot-kanban` **não é um fork** do Chatwoot. Ele é distribuído como um pacote/add-on que se instala sobre uma árvore de código limpa do Chatwoot (CE ou compatíveis).

Nosso objetivo primordial é a **mínima invasão possível ao código core**:
- Upgrades do Chatwoot (ex: v4.18 -> v4.19) devem exigir o menor esforço possível de manutenção.
- O código do Kanban nunca deve desabilitar, remover ou sobrescrever funcionalidades nativas do Chatwoot.
- O pacote deve ser reversível via `./scripts/uninstall.sh`, devolvendo o repositório Chatwoot ao seu estado original limpo.

---

## 2. A Pirâmide de Extensibilidade

Ao implementar qualquer funcionalidade ou ajuste, siga rigorosamente a hierarquia abaixo:

```
                  ▲
                 / \
                /   \
               /  3  \  Patches Cirúrgicos Aditivos (Último Recurso)
              /-------\
             /    2    \  Rails Hooks & Initializers (0 Patches no Backend)
            /-----------\
           /      1      \  Overlay Puro (Prioridade Máxima - 0 Risco)
          /_______________\
```

### Camada 1: Overlay Puro (`overlay/`) — Prioridade Máxima
Todo código novo deve viver em `overlay/`:
- **Models novos:** `KanbanBoard`, `KanbanCard`, `KanbanStage`, etc.
- **Controllers novos:** `Api::V1::Accounts::KanbanBoardsController`, etc.
- **Services e Jobs novos:** `KanbanCards::CreateFromConversationService`, `KanbanAutomations::ScanTimeBasedJob`, etc.
- **Frontend novo:** Páginas, rotas internas do Kanban, stores Vuex e componentes em `overlay/app/javascript/dashboard/routes/dashboard/kanban/`.
- **Migrations:** Em `overlay/db/migrate/`.
- **Specs e Testes:** Em `overlay/spec/` e `overlay/app/javascript/.../specs/`.

*Arquivos em `overlay/` são copiados diretamente e nunca geram conflito de `git apply`.*

---

### Camada 2: Rails Hooks & Initializers (`overlay/config/initializers/`) — Para o Backend Core
Sempre que o Kanban precisar estender um model, service ou controller existente do Chatwoot, **NÃO crie um `.patch`**. Utilize os pontos de extensão nativos do Rails executados no boot da aplicação:

- **Associações em Models existentes:**
  ```ruby
  # Em overlay/config/initializers/kanban_core_extensions.rb
  Rails.application.config.to_prepare do
    Account.class_eval do
      has_many :kanban_automation_rules, dependent: :destroy_async unless reflect_on_association(:kanban_automation_rules)
    end
  end
  ```
- **Extensão de comportamentos via `prepend` ou `include`:**
  ```ruby
  Rails.application.config.to_prepare do
    ActionService.include(KanbanActionService)
    Labels::UpdateService.prepend(KanbanLabelsUpdateServiceExtension)
  end
  ```
- **Parâmetros adicionais em Controllers (`prepend`):**
  Use `prepend` para estender métodos de *strong parameters* sem tocar no controller original.

*Vantagem:* Reduz o número de patches a zero no backend. Atualizações de código do Chatwoot upstream não quebram a instalação.

---

### Camada 3: Patches Cirúrgicos Aditivos (`patches/common/`) — Último Recurso
Usado **apenas** onde o Chatwoot não oferece ponto de injeção dinâmico (principalmente templates Vue e rotas estáticas):
- Injeção do item de menu em `Sidebar.vue`.
- Injeção da rota `/kanban` em `dashboard.routes.js`.
- Registro de módulos Vuex em `store/index.js`.
- Chaves de tradução em `i18n/locale/*/*.json` e `config/locales/*.yml`.

### ⚠️ Regra de Ouro dos Patches: SEMPRE ADITIVO
1. **NUNCA remova linhas do Chatwoot upstream:** Linhas marcadas com `-` no diff que apaguem código original quebram funcionalidades nativas da versão alvo.
2. **Contexto mínimo:** Mantenha os blocos de contexto do patch o mais curtos possível para resistir a movimentações de código no arquivo alvo.
3. **Verificação de Contaminação:** Certifique-se de que o patch não contém sobras de forks (recursos como WAHA, menus não relacionados, listeners de digitação alheios ao Kanban).

---

## 3. Estrutura do Repositório

```
chatwoot-kanban/
├── overlay/                 # Arquivos novos copiados integralmente para o alvo
│   ├── app/                 # Models, controllers, services, helpers, frontend
│   ├── config/              # Initializers nativos e agendamentos
│   ├── db/migrate/          # Migrations com timestamps reconciliados
│   └── spec/                # Suíte de specs completa (RSpec e Vitest)
├── patches/
│   ├── common/              # Patches compartilhados para todos os alvos
│   ├── vanilla/             # Patches exclusivos para Chatwoot CE puro
│   └── fazer-ai/            # Patches específicos para o fork fazer-ai
├── scripts/
│   ├── install.sh           # Script de instalação com validação de versão
│   ├── uninstall.sh         # Rollback limpo (remove overlay e reverte patches)
│   ├── reconcile_migrations.rb  # Reconciliação do schema_migrations
│   ├── test-package.sh      # Validação estática de sintaxe e integridade
│   └── run-specs.sh         # Execução dos specs contra um Chatwoot funcional
└── docs/
    └── ARCHITECTURE.md      # Este documento
```

---

## 4. Como Validar Suas Mudanças Antes de Comitar

Antes de abrir um Pull Request ou subir commits, execute a validação de integridade local:

```bash
# 1. Validação estática rápida de integridade do pacote
./scripts/test-package.sh

# 2. Teste de instalação e rollback contra uma árvore de teste limpa
./scripts/install.sh /caminho/para/chatwoot-teste --target vanilla
./scripts/uninstall.sh /caminho/para/chatwoot-teste --target vanilla
# O git status da árvore de teste deve voltar a ficar 100% limpo!
```
