# 📈 Guia de Relatórios Analíticos & Métricas Comerciais

> **Módulo:** `chatwoot-kanban`  
> **Autor & Engenharia:** Gihovani Demetrio (GG2) — [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)  
> **Compatibilidade:** Chatwoot v4.18.x (CE & Forks)

---

## 📖 Visão Geral

O painel de **Relatórios do Kanban (`/settings/reports/kanban`)** entrega visão estratégica sobre a eficiência do time comercial, identificando gargalos na esteira de atendimento e previsibilidade de receita.

Todas as consultas contam com cache em memória (Redis/Rails) de 5 minutos, garantindo alta performance mesmo em contas com milhares de conversas.

---

## 📊 Relatórios Nativos Disponíveis

1. **Taxa de Conversão do Funil (`conversion`):** Porcentagem de leads que avançam entre cada estágio e taxa global de conversão (Leads ➔ Ganhos).
2. **Tempo Médio por Estágio (`stage_times`):** Quantas horas ou dias as oportunidades passam paradas em cada etapa.
3. **Desempenho por Atendente (`agents`):** Volume de cartões atendidos, tempo médio de resposta e taxa de fechamento por vendedor.
4. **Volume Won / Lost (`won_lost`):** Comparativo temporal de faturamento e negócios ganhos versus perdidos.
5. **Análise de Motivos de Perda (`loss_reasons`):** Gráfico de Pareto apontando as principais causas de cancelamento ou perda.
6. **Vendas por Produto (`products`):** Ranking dos produtos mais cotados e mais vendidos no catálogo.

---

## 🎯 Catálogo de Casos de Uso Práticos

---

### 📌 Caso de Uso #1: Identificação de Gargalos de Atendimento
* **Cenário / Problema:** A empresa investe muito em tráfego pago, mas as vendas não sobem. A diretoria precisa saber onde os clientes estão travando.
* **Métrica Consultada:** **Tempo Médio por Estágio** (`stage_times`).
* **Diagnóstico na Prática:**
  * Se a etapa *Primeiro Contato* registra média de **32 horas**, o gargalo é o tempo de resposta inicial dos atendentes.
  * Se a etapa *Proposta Enviada* registra média de **15 dias**, o time precisa implementar uma regra de automação de follow-up (`no_reply` após 24h/48h).

---

### 📌 Caso de Uso #2: Reunião Mensal de Desempenho e Metas por Vendedor
* **Cenário / Problema:** O gestor comercial precisa auditar o número de negócios fechados e a taxa de conversão individual de cada atendente.
* **Métrica Consultada:** **Desempenho por Agente** (`agents`).
* **Como Exportar:**
  1. Acesse **Configurações** ➔ **Relatórios** ➔ **Kanban**.
  2. Filtre pelo mês desejado.
  3. Clique em **"Exportar CSV"** na tabela de atendentes para gerar a planilha de comissões.

---

## 💬 Contato & Comunidade

Dúvidas, sugestões ou interesse em contribuir com o projeto:
* 💼 **LinkedIn:** [linkedin.com/in/gihovani](https://www.linkedin.com/in/gihovani/)
* ✉️ **E-mail:** [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)
