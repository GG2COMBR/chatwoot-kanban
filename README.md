# chatwoot-kanban

> **Kanban de Vendas e CRM Nativo para Chatwoot**  
> Desenvolvido e mantido por **Gihovani Demetrio** (GG2)  
> [![License: PolyForm Noncommercial](https://img.shields.io/badge/License-PolyForm%20Noncommercial-blue.svg)](LICENSE)

Kanban de vendas (funil) nativo para o Chatwoot, distribuído como um pacote instalável sobre uma árvore de código do Chatwoot — sem fork permanente, sem reescrever o core. O objetivo é ser *plug-and-play*: você aplica o pacote, roda as migrations e o Kanban aparece integrado ao dashboard.

---

## 🚀 Implantação Profissional & Serviços Especializados

Quer colocar o Kanban rodando na sua empresa sem riscos e sem dor de cabeça técnica?

Oferecemos serviços completos de engenharia e suporte para a sua operação:
- 🛠️ **Instalação e Rollout Assistido:** Implantação em instâncias Chatwoot existentes (Docker, Kubernetes, Coolify, Portainer, CapRover).
- ⚡ **Desenvolvimento de Customizações & Integrações:** Conexão com seu ERP, webhooks customizados, funis sob medida e regras de automação avançadas.
- 🏷️ **Licenciamento Comercial:** Liberação para uso em provedores de SaaS ou distribuição comercial.
- 🎓 **Treinamento & Suporte Contínuo:** Capacitação da equipe comercial e acompanhamento de atualizações.

### 💬 Entre em contato:
- 📲 **WhatsApp:** [wa.me/gihovani](https://wa.me/gihovani)
- 💼 **LinkedIn:** [linkedin.com/in/gihovani](https://www.linkedin.com/in/gihovani/)
- ✉️ **E-mail Comercial:** [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)

---

## O que inclui

- **Boards (funis)** com estágios e cards por drag-and-drop.
- **Cards** a partir de conversas ou manuais; vínculo conversa↔board sem duplicar entidades do core.
- **Won/Lost** com motivos, prioridade, SLA por estágio, agendamento.
- **Catálogo de produtos** nativo com importação inteligente de CSV (autodetecção de separadores e moedas) e feeds Google Merchant XML, além de promoções "De / Por".
- **Campos personalizados** por funil e cotação de produtos por oportunidade.
- **Automações nativas** do Kanban (7 ações: mover estágio, prioridade, etiquetas, vencimento, notas, atribuição e perda com motivos).
- **Relatórios** de funil: conversão, won/lost, tempo por estágio, por agente, por produto.
- **Entry rules** por inbox; membros e visibilidade por board.
- **Multi-tenant estrito** com feature flags por conta (`kanban`, `kanban_products`).

## Compatibilidade

| Alvo | Versão | Status |
| :-- | :-- | :-- |
| Chatwoot CE (vanilla) | v4.18.x | validado e funcional |
| fork fazer-ai | v4.18.x | em preparação (`patches/fazer-ai`) |

Os patches de integração são sensíveis à versão. Use a versão homologada em `VERSION_COMPAT`. Em versões diferentes, o `install.sh` aborta com mensagem clara (não corrompe a árvore).

## Instalação

Pré-requisitos: uma árvore de código do Chatwoot (git), árvore limpa (para permitir rollback).

```bash
# a partir da raiz deste repositório
./scripts/install.sh /caminho/para/o/chatwoot --target vanilla
```

O script:
1. valida a versão do Chatwoot alvo;
2. copia os arquivos novos (`overlay/`);
3. aplica os patches de integração (`patches/common` + `patches/<target>`).

Depois, no ambiente do Chatwoot:

```bash
bundle exec rails db:migrate     # cria as tabelas kanban_*
# dev: o Vite recompila ao subir | prod: rake assets:precompile
# reinicie rails + sidekiq
```

O menu **Kanban** aparece na barra lateral.

## Desinstalação

```bash
./scripts/uninstall.sh /caminho/para/o/chatwoot --target vanilla
```

Reverte os patches e remove os arquivos do overlay. As migrations **não** são revertidas automaticamente (há perda de dados) — faça o rollback manualmente se desejar remover as tabelas.

## Documentação

- 📘 **[Guia do Usuário e Administrador (docs/USER_GUIDE.md)](docs/USER_GUIDE.md)**: Manual operacional completo cobrindo arquitetura multi-tenant, feature flags por conta, cadastro de motivos de ganho/perda, catálogo de produtos (importação CSV inteligente e Google Merchant XML), regras de automação com exemplos e auditoria em tempo real.
- 🏗️ **[Arquitetura do Pacote (docs/ARCHITECTURE.md)](docs/ARCHITECTURE.md)**: Pirâmide de extensibilidade, governança de patches aditivos (Regra de Ouro) e isolamento em relação ao core do Chatwoot.
- 🛡️ **[Pre-flight para Produção (docs/PRODUCTION_PREFLIGHT.md)](docs/PRODUCTION_PREFLIGHT.md)**: Runbook de validação SQL e integridade de dados antes de executar migrations em bases de produção existentes.

## Arquitetura do pacote

Consulte o documento completo em **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** para entender a **Pirâmide de Extensibilidade** e as regras de desenvolvimento para novos contribuidores.

```
overlay/      arquivos NOVOS copiados as-is (models, controllers, migrations, front, initializers)
patches/
  common/     patches cirúrgicos e estritamente aditivos compartilhados
  fazer-ai/   edições específicas do fork fazer-ai
  vanilla/    edições específicas do Chatwoot CE puro
scripts/      install.sh, uninstall.sh, test-package.sh, run-specs.sh, reconcile_migrations.rb
docs/         guias de usuário, arquitetura e pre-flight de produção
```

### Desenvolvimento & Pre-commit Hooks

Para configurar o ambiente de desenvolvimento e ativar a validação automática em cada `git commit`:

```bash
./scripts/setup-dev.sh
```

Isso ativa os hooks nativos versionados em `.githooks/pre-commit`, garantindo que:
- Todos os arquivos Ruby tenham sintaxe válida;
- Todos os patches e o `MANIFEST.txt` estejam sincronizados e integros;
- Nenhuma contaminação ou dependência oculta de forks seja introduzida;
- A regra de ouro de patches estritamente aditivos seja respeitada.

Para rodar a validação manualmente a qualquer momento:

```bash
./scripts/test-package.sh
```

## Estado atual

- **Fase A (Board Principal):** 100% concluída e validada em Chatwoot v4.18 (banco, migrations, build Vite e telas de funil/cards funcionais).
- **Fase B (Multi-tenant & Catálogo):** Multi-tenant por conta via feature flags, suporte a motivos de ganho/perda, catálogo de produtos interno com importação inteligente de CSV / Google Merchant XML e 7 regras de automação testadas com auditoria em tempo real.
- **Governança & Extensibilidade:** Arquitetura limpa estabelecida priorizando *Overlay First* e *Rails Initializers* para manter o core imune a conflitos de atualização.

---

## Licença e Atribuição

Desenvolvido e mantido por **Gihovani Demetrio** ([gihovani@gg2.com.br](mailto:gihovani@gg2.com.br)).

Este projeto é distribuído sob os termos da **PolyForm Noncommercial License 1.0.0** — consulte o arquivo [LICENSE](LICENSE) para detalhes completos.

- ✅ **Uso Livre e Gratuito:** Permitido para uso pessoal, interno, estudos, testes e desenvolvimento não-comercial, desde que mantida a atribuição ao autor original.
- ❌ **Uso Comercial Restrito:** É vedado vender, sublicenciar, cobrar mensalidades/taxas ou revender este software como produto comercial próprio ou serviço SaaS de terceiros sem autorização prévia.
- 💼 **Licença Comercial & Customizações:** Para uso comercial direto ou projetos corporativos sob medida, entre em contato via [WhatsApp](https://wa.me/gihovani) ou [gihovani@gg2.com.br](mailto:gihovani@gg2.com.br).

*Componentes históricos e adaptados do Chatwoot Inc. e comunidade sob licença MIT têm seus respectivos avisos de copyright integralmente preservados em [LICENSE](LICENSE).*
