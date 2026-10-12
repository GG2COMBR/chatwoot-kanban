# Matriz de Casos de Uso & Especificação de Testes E2E (Playwright)

Este documento especifica os cenários de teste ponta a ponta (E2E) críticos do módulo **chatwoot-kanban**. Cada caso de uso é descrito no formato **BDD / Gherkin** (`Dado / Quando / Então`), servindo como especificação viva para a implementação dos testes automatizados via Playwright.

---

## 1. Autenticação & Navegação no Módulo

### UC-01: Acesso ao Painel Kanban via Navegação Lateral
- **Objetivo:** Garantir que um usuário com a feature `kanban` ativa consiga visualizar o módulo no menu principal e acessar o board.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário está autenticado no Chatwoot como administrador
  E a conta possui a feature "kanban" habilitada
  Quando ele acessa o dashboard principal ("/app/accounts/{account_id}/dashboard")
  Então o item "Kanban" deve estar visível na barra de navegação lateral
  Quando o usuário clica no item "Kanban"
  Então a URL deve mudar para "/app/accounts/{account_id}/kanban"
  E a interface do painel Kanban deve ser renderizada sem erros no console
  ```

### UC-02: Bloqueio Elegante quando Feature Flag está Desativada
- **Objetivo:** Garantir que contas sem a feature `kanban` não acessem o módulo ou vejam mensagem adequada de permissão.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário pertence a uma conta com a feature "kanban" desabilitada
  Quando ele tenta navegar diretamente para "/app/accounts/{account_id}/kanban"
  Então o sistema não deve exibir a listagem de boards
  E a API deve responder com status 401 Unauthorized ou exibir tela de acesso negado
  ```

---

## 2. Gestão de Pipelines (Boards & Estágios)

### UC-03: Criação de Novo Pipeline com Estágios Padrão
- **Objetivo:** Validar a criação completa de um novo board de oportunidades.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário está na tela inicial de Kanban
  Quando ele clica no botão "Novo Pipeline" / "Criar Funil"
  E preenche o nome do pipeline como "Funil Comercial de Teste"
  E define as configurações de exibição (ex: habilitar produtos e valores monetários)
  E submete o formulário
  Então o novo pipeline deve ser criado via API com status 200/201
  E o usuário é redirecionado para a visualização do board
  E as colunas de estágios padrão ("Lead", "Em Negociação", "Ganho", "Perdido") devem estar visíveis
  ```

### UC-04: Customização e Reordenação de Estágios
- **Objetivo:** Adicionar novas etapas ao funil e ajustar suas posições.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário está visualizando as configurações de estágios do pipeline
  Quando ele adiciona uma nova etapa com nome "Aguardando Contrato" e cor "#3B82F6"
  Então a nova coluna deve ser inserida no board
  Quando o usuário arrasta ou altera a posição do estágio para antes de "Ganho"
  Então a nova ordem de estágios deve persistir após recarregamento da página
  ```

---

## 3. Gestão e Ciclo de Vida de Oportunidades (Cards)

### UC-05: Criação Manual de Card de Oportunidade
- **Objetivo:** Permitir que o atendente crie uma oportunidade diretamente na coluna desejada.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário está visualizando as colunas do pipeline
  Quando ele clica em "Adicionar Card" na coluna "Lead"
  E preenche o título "Proposta Empresa Alpha"
  E define o valor monetário como "R$ 5.000,00"
  E seleciona um contato existente ou informa dados de contato
  E clica em "Salvar"
  Então o card deve aparecer imediatamente na coluna "Lead"
  E o total monetário do estágio "Lead" deve ser recalculado e atualizado no cabeçalho
  ```

### UC-06: Movimentação de Card entre Estágios (Transição de Funil)
- **Objetivo:** Arrastar o card de uma etapa para outra e persistir a nova fase.
- **Cenário (BDD):**
  ```gherkin
  Dado que existe um card "Proposta Empresa Alpha" no estágio "Lead"
  Quando o usuário arrasta o card para a coluna "Em Negociação"
  Então a API deve registrar a transição de estágio com sucesso
  E o card deve permanecer na coluna "Em Negociação"
  E os somatórios de valores de ambos os estágios devem ser atualizados
  E a timeline de eventos do card deve registrar o evento de mudança de estágio
  ```

### UC-07: Detalhes, Anotações Internas e Prioridade do Card
- **Objetivo:** Abrir a gaveta lateral do card para editar atributos e adicionar notas.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário clica sobre o card "Proposta Empresa Alpha"
  Então o modal/painel lateral de detalhes do card deve abrir
  Quando o usuário altera a prioridade para "Alta"
  E escreve uma nota interna: "Cliente solicitou desconto para pagamento à vista"
  E salva a nota
  Então a nota deve aparecer na lista de histórico do card com data e autor
  E a etiqueta visual de prioridade alta deve ser visível no card na coluna
  ```

---

## 4. Conclusão de Negócios (Ganho e Motivo de Perda)

### UC-08: Conclusão com Sucesso (Negócio Ganho)
- **Objetivo:** Mover uma oportunidade para a etapa de Ganho.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário move o card para o estágio marcado como "Ganho"
  Então o status do card passa para concluído/ganho
  E o valor total ganho do pipeline deve refletir o valor deste card
  E o card deve exibir indicador visual de negócio fechado
  ```

### UC-09: Exigência Obrigatória de Motivo de Perda
- **Objetivo:** Garantir a governança ao marcar uma oportunidade como perdida quando a regra exige motivo.
- **Cenário (BDD):**
  ```gherkin
  Dado que o pipeline possui a opção "Exigir motivo ao perder" habilitada
  E existem motivos cadastrados (ex: "Preço", "Prazo", "Concorrente")
  Quando o usuário move o card para a coluna "Perdido"
  Então um modal de confirmação deve ser exibido solicitando o motivo da perda
  Quando o usuário tenta confirmar sem selecionar o motivo
  Então uma mensagem de validação deve impedir a conclusão
  Quando o usuário seleciona o motivo "Preço" e confirma
  Então o card é arquivado/marcado como "Perdido" associado ao motivo selecionado
  ```

---

## 5. Integração com Catálogo de Produtos

### UC-10: Associação de Produtos ao Card e Atualização de Valor
- **Objetivo:** Adicionar itens do catálogo interno a uma oportunidade e calcular o total automaticamente.
- **Cenário (BDD):**
  ```gherkin
  Dado que a feature "kanban_products" está ativa e existem produtos cadastrados no catálogo
  Quando o usuário abre os detalhes do card no pipeline
  E acessa a aba "Produtos"
  E busca e seleciona o produto "Plano Pro Anual" (Preço unitário: R$ 1.200,00)
  E define a quantidade como 2
  E clica em "Adicionar ao Card"
  Então o valor do card deve ser atualizado para "R$ 2.400,00"
  E a lista de produtos do card deve exibir "2x Plano Pro Anual"
  E o valor total do card no board deve refletir o novo total calculado
  ```

---

## 6. Motor de Automações & Regras de Entrada do Funil

### UC-11: Motor de Automações, Kill Switch e Regras de Entrada
- **Objetivo:** Validar a governança de regras de ciclo de vida, interruptor geral (kill-switch), modal de nova regra e regras de entrada por inboxes.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário está na tela de configurações do pipeline ("/app/accounts/{account_id}/kanban/{board_id}/edit")
  Quando ele acessa a aba "Automações"
  Então o Kill Switch de automações do funil deve estar visível e ativo
  E o botão de "Adicionar Regra" deve estar disponível
  Quando o usuário clica em "Adicionar Regra"
  Então o modal de criação de regra deve exibir os campos obrigatórios (Nome, Evento/Gatilho, Ação)
  Quando o usuário acessa a aba "Regras de Entrada"
  Então os controles de escopo de inboxes e criação automática de cards devem ser renderizados
  Quando o usuário navega para as configurações globais do Chatwoot ("/app/accounts/{account_id}/settings/automations")
  Então a tela de automações do core deve carregar sem erros contendo as ações estendidas do Kanban
  ```

---

## 7. Relatórios de Performance do Kanban

### UC-12: Visualização de Métricas de Conversão e Desempenho
- **Objetivo:** Validar que os dashboards de relatórios carregam os gráficos nativos corretamente.
- **Cenário (BDD):**
  ```gherkin
  Dado que o usuário navega para o funil e aciona o View Switcher "Dashboard"
  Então as métricas de resumo (Oportunidades no funil, Valor total em aberto) devem ser exibidas
  E os gráficos nativos ("Ganhos x perdidos", "Origem", "Funil por etapa") devem ser renderizados
  Quando o usuário acessa os relatórios gerais da conta ("/app/accounts/{account_id}/reports/kanban")
  Então o cabeçalho e os cartões de cartões abertos e ganhos devem ser renderizados sem erros
  ```

---

## 8. Critérios de Execução da Suíte E2E

1. **Isolamento de Estado:** Os testes devem executar em um banco de desenvolvimento preparado ou usar fixtures que criem e limpem suas próprias entidades.
2. **Reuso de Sessão:** A autenticação do usuário administrador deve ser realizada no setup do Playwright via `storageState` (`playwright/.auth/user.json`) para evitar overhead de login repetitivo.
3. **Resiliência a Renderização Assíncrona:** Utilizar `locator.waitFor()` e seletores semânticos ou `data-testid` para garantir estabilidade mesmo em redes lentas ou compilação HMR do Vite.
