# Compatibilidade

Pacote de Kanban de vendas para Chatwoot, projetado para ser instalável sobre
diferentes "sabores" do Chatwoot (plugin-and-play).

## Versões-alvo

| Alvo | Versão base | Status |
| :-- | :-- | :-- |
| fazer.ai fork | v4.18.0 | em homologação (alvo primário) |
| Chatwoot CE (vanilla) | v4.14+ | planejado |

A fonte do Kanban foi extraída de um fork baseado em **Chatwoot v4.14.0**.
O porte para o fazer-ai v4.18.0 trata o gap de 4 versões (ver `PLANO.md`).

## O que o pacote adiciona

- Boards (funis) com estágios, cards com drag-and-drop.
- Cards a partir de conversas ou manuais; vínculo conversa↔board via
  `conversation_kanban_state` (sem duplicar entidades do core).
- Won/Lost com motivos, prioridade, SLA por estágio, agendamento.
- Campos personalizados por funil; produtos por card (via API externa de busca).
- Automações próprias do Kanban (regras, triggers, logs, guardrails).
- Relatórios de funil: conversão, won/lost, tempo por estágio, por agente, por produto.
- Entry rules por inbox; membros/visibilidade por board.

## O que NÃO é portado (o core/fork já provê)

Diferente de outros módulos, este NÃO duplica recursos do Chatwoot. As notas e
assignees são **escopadas ao card** (`kanban_card_note`, `kanban_card_assignee`)
e não substituem notas/participantes de conversa do core.

Para o alvo fazer-ai especificamente, preservar os recursos próprios do fork
(conector WhatsApp nativo, chat interno, grupos) — os patches de integração não
devem sobrescrever esses arquivos; apenas acrescentar os pontos do Kanban.

## Modelo de dados (tabelas criadas)

Todas sob prefixo `kanban_*` + `conversation_kanban_states`. Nenhuma colide com
tabelas existentes do Chatwoot/fazer-ai (verificado: o fork aberto não possui
nenhuma tabela de kanban).
