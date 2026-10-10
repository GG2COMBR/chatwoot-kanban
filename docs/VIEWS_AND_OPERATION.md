# 🖥️ Guia de Operação Comercial: Visões Kanban, Lista e Agenda

> **Módulo:** `chatwoot-kanban`  
> **Autor & Engenharia:** Gihovani Demetrio (GG2) — [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)  
> **Compatibilidade:** Chatwoot v4.18.x (CE & Forks)

---

## 📖 Visão Geral

A interface do `chatwoot-kanban` oferece **3 modos de visualização** complementares, desenhados para atender diferentes momentos da rotina comercial:

1. **Visão Kanban (Quadro):** Ideal para reuniões de pipeline e avanço tático por drag-and-drop.
2. **Visão Lista (Tabela com Ações em Massa):** Ideal para reatribuição rápida, ordenação por valor e filtros densos.
3. **Visão Agenda (Calendário):** Ideal para a rotina diária do vendedor focada em prazos de vencimento (`due_at`) e follow-ups agendados.

---

## 🎯 Catálogo de Casos de Uso Práticos

---

### 📌 Caso de Uso #1: A Rotina Matinal do Vendedor na Visão Agenda
* **Cenário / Problema:** O vendedor inicia o expediente e precisa saber quais contatos precisam de retorno imediato hoje.
* **Passo a Passo na Interface:**
  1. No canto superior direito do funil, mude a visualização para **Agenda** (`KanbanAgendaView`).
  2. A tela exibe o calendário semanal/mensal com os cards alocados no dia do vencimento (`due_at`).
  3. Cards em atraso aparecem destacados em vermelho na barra lateral de pendências.
* **Resultado:** Foco operacional absoluto: o vendedor cumpre seus prazos sem perder vendas por esquecimento.

---

### 📌 Caso de Uso #2: Reatribuição em Massa de Carteira na Visão Lista
* **Cenário / Problema:** Um atendente saiu de férias ou foi promovido, e 40 oportunidades precisam ser transferidas para outro vendedor.
* **Passo a Passo na Interface:**
  1. Mude a visualização para **Lista** (`KanbanListView`).
  2. Filtre por Atendente = *Vendedor Antigo*.
  3. Marque o checkbox para selecionar todos os cartões.
  4. Na barra inferior de **Ações em Massa (`KanbanBulkActions`)**, selecione **Atribuir Agente** ➔ Escolha o novo vendedor.
* **Resultado:** 40 oportunidades transferidas em menos de 5 segundos.

---

## 💬 Contato & Comunidade

Dúvidas, sugestões ou interesse em contribuir com o projeto:
* 💼 **LinkedIn:** [linkedin.com/in/gihovani](https://www.linkedin.com/in/gihovani/)
* ✉️ **E-mail:** [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)
