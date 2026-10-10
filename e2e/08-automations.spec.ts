import { test, expect } from '@playwright/test';

test.describe('UC-11: Motor de Automações & Regras de Entrada do Kanban', () => {
  test.beforeEach(async ({ page, baseURL }) => {
    // 1. Acessa diretamente a tela de edição e configurações do pipeline principal
    await page.goto(`${baseURL}/app/accounts/1/kanban/1/edit`);
    await page.waitForLoadState('domcontentloaded');

    // 2. Aguarda a inicialização do formulário de edição do funil
    await expect(page.getByTestId('kanban-board-form-stages-tab')).toBeVisible({ timeout: 25000 });
  });

  test('deve acessar a aba de automações de ciclo de vida e validar o kill-switch e controles de regras', async ({ page }) => {
    // 1. Clica na aba de Automações
    const automationsTabBtn = page.locator('button, div[role="tab"]').filter({ hasText: /Automações|Automations/i }).first();
    await expect(automationsTabBtn).toBeVisible({ timeout: 10000 });
    await automationsTabBtn.click();

    // 2. Valida que a seção de automações está ativa e visível
    const automationsSection = page.getByTestId('kanban-automations-tab');
    await expect(automationsSection).toBeVisible({ timeout: 10000 });

    // 3. Valida o Kill Switch de automações do funil
    const killSwitch = page.getByTestId('kanban-automations-kill-switch');
    await expect(killSwitch).toBeVisible();

    // 4. Valida a presença do botão de adicionar nova regra
    const addRuleBtn = page.getByTestId('kanban-automations-add-rule').first();
    await expect(addRuleBtn).toBeVisible();

    // 5. Clica para abrir o modal de configuração de regra
    await addRuleBtn.click();

    // 6. Valida que o modal de criação de regra abriu com os campos essenciais
    const nameInput = page.getByTestId('kanban-automation-rule-name');
    await expect(nameInput).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('kanban-automation-rule-event')).toBeVisible();
    await expect(page.getByTestId('kanban-automation-rule-submit')).toBeVisible();

    // 7. Fecha o modal clicando em cancelar
    const cancelBtn = page.locator('button').filter({ hasText: /Cancelar|Cancel/i }).first();
    if (await cancelBtn.isVisible()) {
      await cancelBtn.click();
    }
  });

  test('deve acessar a aba de regras de entrada do funil e validar controles de inboxes', async ({ page }) => {
    // 1. Clica na aba de Regras de Entrada
    const entryRulesTabBtn = page.locator('button, div[role="tab"]').filter({ hasText: /Regras de entrada|Entry rules/i }).first();
    await expect(entryRulesTabBtn).toBeVisible({ timeout: 10000 });
    await entryRulesTabBtn.click();

    // 2. Valida que a seção de regras de entrada está renderizada
    const entryRulesSection = page.getByTestId('kanban-board-form-entry-rules-tab');
    await expect(entryRulesSection).toBeVisible({ timeout: 10000 });
  });

  test('deve acessar as configurações globais de automação do Chatwoot', async ({ page, baseURL }) => {
    // 1. Navega para a tela de automações do Chatwoot onde as ações do Kanban são injetadas
    await page.goto(`${baseURL}/app/accounts/1/settings/automations`);
    await page.waitForLoadState('domcontentloaded');

    // 2. Valida que o cabeçalho e tela de automações carregaram corretamente
    await expect(page.locator('body')).toContainText(/Automaç|Automation/i, { timeout: 20000 });
  });
});
