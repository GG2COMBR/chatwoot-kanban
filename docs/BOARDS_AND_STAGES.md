# 📊 Guia de Funis, Etapas & SLAs: Casos de Uso & Configuração

> **Módulo:** `chatwoot-kanban`  
> **Autor & Engenharia:** Gihovani Demetrio (GG2) — [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)  
> **Compatibilidade:** Chatwoot v4.18.x (CE & Forks)

---

## 📖 Visão Geral

O módulo **Funis & Estágios (`KanbanBoard` e `KanbanStage`)** é o coração da organização visual do `chatwoot-kanban`.

Ele permite estruturar processos de vendas consultivas, pós-venda, sucesso do cliente (CS) ou atendimento de suporte técnico em colunas Kanban, com **controle de permissões por agente**, **cores customizadas** e **alertas de SLA (Service Level Agreement)** por etapa.

---

## 🛡️ Principais Capacidades

### 1. Múltiplos Funis Isolados por Finalidade
Crie funis independentes para cada área da empresa:
* *Funil Comercial B2B* (com produtos e valores monetários ativados).
* *Funil de Onboarding / Implantação* (focado em prazos e tarefas).
* *Funil de Suporte N2 / Técnico* (valores monetários ocultos).

### 2. Controle Granular de Visibilidade (`visibility_mode`)
* **Todos os Atendentes (`all_agents`):** Toda a equipe tem acesso ao funil.
* **Atendentes Selecionados (`selected_agents`):** Apenas usuários ou gestores autorizados visualizam os cartões daquele funil.

### 3. SLAs por Etapa (`sla_hours`) com Indicadores Visuais
Defina quantas horas um cartão pode permanecer em determinada coluna antes de estourar o prazo:
* Exemplo: *Primeiro Contato (SLA 4h)*, *Elaboração de Proposta (SLA 24h)*.
* Se o cartão exceder as horas configuradas, o sistema exibe indicadores visuais de atraso para o operador.

### 4. Estágios Terminais Especiais (Won / Lost)
* Toda diretoria precisa medir taxa de conversão. O funil permite mapear explicitamente qual coluna representa a vitória (*Ganho*) e qual representa o encerramento (*Perdido*).

---

## 🎯 Catálogo de Casos de Uso Práticos

---

### 📌 Caso de Uso #1: Funil de Vendas B2B de Alta Conversão
* **Cenário / Problema:** Vendas de ciclo longo que exigem qualificação detalhada, envio de proposta e fechamento.
* **Configuração de Estágios:**
  1. `1. Lead Recebido` (Azul `#3b82f6` | SLA: 4 horas)
  2. `2. Reunião / Diagnóstico` (Amarelo `#eab308` | SLA: 24 horas)
  3. `3. Proposta Enviada` (Laranja `#f97316` | SLA: 48 horas)
  4. `4. Em Negociação` (Roxo `#8b5cf6` | SLA: 72 horas)
  5. `5. Ganho` (Verde `#10b981` | Estágio Terminal `won_stage`)
  6. `6. Perdido` (Cinza/Vermelho `#ef4444` | Estágio Terminal `lost_stage`)
* **Toggles Ativos:** `enable_products: true`, `show_monetary_values: true`, `lost_reason_required: true`.
* **Resultado:** Visibilidade total da receita prevista em cada estágio do pipeline.

---

### 📌 Caso de Uso #2: Funil de Onboarding / Suporte Técnico (Sem Valores em R$)
* **Cenário / Problema:** O time técnico precisa acompanhar a instalação de clientes, mas não deve ter acesso aos valores das negociações nem ao catálogo de produtos.
* **Configuração:**
  1. Estágios: `Aguardando Dados` ➔ `Configuração do Servidor` ➔ `Testes Finais` ➔ `Entregue`.
  2. Desative: **"Habilitar catálogo de produtos"** (`enable_products: false`).
  3. Desative: **"Exibir valores monetários"** (`show_monetary_values: false`).
  4. Visibilidade: Restrita aos membros da equipe técnica (`selected_agents`).
* **Resultado:** Interface enxuta e focada em tarefas, preservando o sigilo financeiro da empresa.

---

## 💬 Contato & Comunidade

Dúvidas, sugestões ou interesse em contribuir com o projeto:
* 💼 **LinkedIn:** [linkedin.com/in/gihovani](https://www.linkedin.com/in/gihovani/)
* ✉️ **E-mail:** [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)
