import { test, expect } from '@playwright/test';

test.describe('UC-17: Integração Inbox ↔ Funil e Gestão de Etapas na Conversa', () => {
  test('deve exibir o acordeão Kanban na conversa e permitir alterar a etapa diretamente pelo card', async ({ page, baseURL }) => {
    // 1. Acessa a conversa de teste criada no seed
    await page.goto(`${baseURL}/app/accounts/1/conversations/1`);
    await page.waitForURL(/\/app\/accounts\/1\/conversations\/1/, { timeout: 15000 });

    // 2. Aguarda o carregamento da tela de conversa
    await expect(page.locator('.conversation-panel, .conversation--sidebar, .list-group').first()).toBeVisible({ timeout: 15000 });

    // Localiza o botão do acordeão Kanban na barra lateral de contato
    const kanbanAccordionButton = page
      .locator('.conversation--sidebar, .list-group')
      .locator('button.drag-handle')
      .filter({ hasText: /^Kanban$/i })
      .first();
    await expect(kanbanAccordionButton).toBeVisible({ timeout: 15000 });

    // Se o acordeão estiver fechado, clica para expandir
    const isCollapsed = await kanbanAccordionButton.locator('fluent-icon[icon="add"]').isVisible().catch(() => false);
    if (isCollapsed) {
      await kanbanAccordionButton.click();
    }

    // 3. Localiza um card com seletor de etapa regular ou reabre se necessário
    let cardItem = page
      .getByTestId('kanban-conversation-card')
      .filter({ has: page.getByTestId('kanban-stage-select-trigger') })
      .first();

    if (!(await cardItem.isVisible().catch(() => false))) {
      // Se apenas houver card terminal (ex: fechado por teste prévio), clica no status para reabrir
      const terminalBtn = page.getByTestId('kanban-conversation-card-terminal-status').first();
      if (await terminalBtn.isVisible().catch(() => false)) {
        await terminalBtn.click();
        const reopenConfirm = page.locator('button').filter({ hasText: /reabrir|reopen/i }).first();
        if (await reopenConfirm.isVisible({ timeout: 3000 }).catch(() => false)) {
          await reopenConfirm.click();
        }
      }
      cardItem = page.getByTestId('kanban-conversation-card').first();
    }

    await expect(cardItem).toBeVisible({ timeout: 15000 });

    // 4. Localiza o trigger de etapa do card na conversa
    const stageTrigger = cardItem.getByTestId('kanban-stage-select-trigger');
    await expect(stageTrigger).toBeVisible({ timeout: 10000 });

    // 5. Clica no seletor e altera para uma etapa regular alternativa
    const currentText = (await stageTrigger.innerText()).trim();
    const targetStageText = /negociação/i.test(currentText) ? 'Inbox' : 'Em Negociação';

    await stageTrigger.click();
    const stageOption = page.getByTestId('kanban-stage-select-option')
      .filter({ hasText: new RegExp(targetStageText, 'i') })
      .first();
    await expect(stageOption).toBeVisible({ timeout: 10000 });
    await stageOption.click();

    // 6. Verifica que a etapa foi atualizada no card diretamente na conversa
    await expect(stageTrigger).toContainText(new RegExp(targetStageText, 'i'), { timeout: 10000 });
  });

  test('deve permitir criar um novo card para a conversa filtrando funis elegíveis da inbox', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/app/accounts/1/conversations/1`);
    await page.waitForURL(/\/app\/accounts\/1\/conversations\/1/, { timeout: 15000 });

    await expect(page.locator('.conversation-panel, .conversation--sidebar, .list-group').first()).toBeVisible({ timeout: 15000 });

    // Localiza o acordeão do Kanban na barra lateral de contato
    const kanbanAccordionButton = page
      .locator('.conversation--sidebar, .list-group')
      .locator('button.drag-handle')
      .filter({ hasText: /^Kanban$/i })
      .first();
    await expect(kanbanAccordionButton).toBeVisible({ timeout: 15000 });

    // Se o acordeão estiver fechado, clica para expandir
    const isCollapsed = await kanbanAccordionButton.locator('fluent-icon[icon="add"]').isVisible().catch(() => false);
    if (isCollapsed) {
      await kanbanAccordionButton.click();
    }

    const createBtn = page.getByTestId('kanban-conversation-card-create-another')
      .or(page.getByTestId('kanban-conversation-card-create-empty'))
      .first();

    await expect(createBtn).toBeVisible({ timeout: 15000 });
    await createBtn.click();

    // Formulário de criação na conversa aberto
    const form = page.getByTestId('kanban-conversation-card-form');
    await expect(form).toBeVisible({ timeout: 10000 });

    // Se houver mais de um board na conta e nenhum estiver selecionado, seleciona o primeiro
    const boardSelect = form.getByTestId('kanban-conversation-card-board').locator('select');
    if (await boardSelect.isVisible().catch(() => false)) {
      const selectedBoard = await boardSelect.inputValue();
      if (!selectedBoard) {
        await boardSelect.selectOption({ index: 1 });
      }
    }

    // Se a etapa estiver vazia, seleciona a primeira etapa regular
    const stageSelect = form.getByTestId('kanban-conversation-card-stage').locator('select');
    if (await stageSelect.isVisible().catch(() => false)) {
      const selectedStage = await stageSelect.inputValue();
      if (!selectedStage) {
        await stageSelect.selectOption({ index: 1 });
      }
    }

    const newSubject = `Oportunidade Adicional ${Date.now()}`;
    const subjectInput = form.getByTestId('kanban-conversation-card-subject');
    await subjectInput.fill(newSubject);

    // Clica no botão de criar
    const submitBtn = form.getByTestId('kanban-conversation-card-create');
    await expect(submitBtn).toBeEnabled({ timeout: 5000 });
    await submitBtn.click();

    // Verifica que o novo card foi adicionado à lista da conversa
    await expect(page.locator('body')).toContainText(newSubject, { timeout: 15000 });
  });
});
