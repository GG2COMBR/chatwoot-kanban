# 🎯 Guia de Motivos de Perda & Ciclos de Recorrência

> **Módulo:** `chatwoot-kanban`  
> **Autor & Engenharia:** Gihovani Demetrio (GG2) — [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)  
> **Compatibilidade:** Chatwoot v4.18.x (CE & Forks)

---

## 📖 Visão Geral

Vender com inteligência exige saber **por que os negócios são perdidos** e como **reativar clientes automaticamente no momento certo da recompra**.

Este módulo cobre duas funcionalidades estratégicas do `chatwoot-kanban`:
1. **Motivos de Ganho e Perda (`KanbanReason`):** Categorização obrigatória ou opcional do encerramento de negociações para alimentar relatórios de causa-raiz.
2. **Ciclos de Recorrência de Contato (`won_recurrence` / `lost_recurrence`):** Janelas de tempo inteligentes que determinam quando um cliente que comprou (ou perdeu) pode ter um novo cartão criado no funil.

---

## 🛡️ Principais Capacidades

### A. Motivo Obrigatório ao Desqualificar (`lost_reason_required`)
Quando ativado nas configurações do funil:
* O atendente é impedido de arrastar o cartão para o estágio **Perdido** sem selecionar a justificativa em um modal de confirmação.
* Elimina a perda de dados e o clássico problema de "leads perdidos sem explicação".

### B. Janela de Recorrência (Anti-Duplicação e Recompra)
Se um cliente já comprou ou foi perdido:
* **Janela Ativa (ex: 30 dias):** Novas conversas desse cliente durante o período não criam novos cartões duplicados, mantendo o histórico unificado.
* **Após a Janela Expirar:** Se o cliente chamar novamente após os 30 dias, o sistema entende como uma **nova oportunidade de recompra** e abre um novo card no topo do funil.

---

## 🎯 Catálogo de Casos de Uso Práticos

---

### 📌 Caso de Uso #1: Auditoria Obrigatória de Motivo de Perda
* **Cenário / Problema:** A diretoria comercial não sabe se os clientes estão recusando propostas por causa de preço alto, falta de prazo de entrega ou concorrência.
* **Configuração:**
  1. No Funil Comercial ➔ **Configurações** ➔ Aba **"Motivos"**.
  2. Cadastre os motivos de perda:
     * *Preço / Orçamento fora do limite*
     * *Prazo de entrega longo*
     * *Optou pelo concorrente*
     * *Sem resposta / Inacessível*
     * *Lead desqualificado / Perfil incompatível*
  3. Na aba **Geral**, ative o toggle: **"Exigir motivo de perda ao finalizar"** (`lost_reason_required: true`).
* **Resultado:** Nenhum vendedor consegue descartar um lead sem auditar a causa. A aba de Relatórios passa a exibir gráficos precisos de motivos de perda.

---

### 📌 Caso de Uso #2: Ciclo de Recompra Recorrente de 30 Dias (E-commerce / Serviços)
* **Cenário / Problema:** Uma distribuidora de suprimentos vende produtos que acabam a cada 30 dias. Quando o cliente compra, ele não deve ter novos cartões criados durante o mês, mas deve gerar uma nova oportunidade no mês seguinte.
* **Configuração:**
  1. No Funil ➔ **Configurações** ➔ **Recorrência de Venda Ganha**.
  2. Ative: **"Habilitar recorrência para negócios ganhos"** (`won_recurrence_enabled: true`).
  3. Defina a Janela: **`30 dias`** (`43.200 minutos`).
* **Resultado:** Se o cliente mandar mensagem em até 30 dias após a compra (ex: para pedir rastreio ou nota fiscal), a conversa é tratada como suporte pós-venda. Se chamar no 31º dia, um novo cartão comercial é aberto no funil automaticamente.

---

### 📌 Caso de Uso #3: Quarentena de 60 Dias para Leads Desistentes
* **Cenário / Problema:** Um cliente disse que *"não tem interesse agora"*. O vendedor marca como Perdido. A empresa quer que ele fique em quarentena por 60 dias antes de ser reabordado em uma nova campanha.
* **Configuração:**
  1. No Funil ➔ **Configurações** ➔ **Recorrência de Venda Perdida**.
  2. Ative: **"Habilitar recorrência para negócios perdidos"** (`lost_recurrence_enabled: true`).
  3. Defina a Janela: **`60 dias`**.
* **Resultado:** Impede que disparos de mensagens automáticas ou campanhas gerem novos cartões para contatos desqualificados recentemente.

---

## 💬 Contato & Comunidade

Dúvidas, sugestões ou interesse em contribuir com o projeto:
* 💼 **LinkedIn:** [linkedin.com/in/gihovani](https://www.linkedin.com/in/gihovani/)
* ✉️ **E-mail:** [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)
