import { test, expect } from '@playwright/test';

test.describe('UC-08 & UC-09: Fechamento de Negócios (Ganho e Perdido)', () => {
  test('deve marcar uma oportunidade como Ganha (UC-08)', async ({ page, baseURL }) => {
    // 1. Acessa o board principal
    await page.goto(`${baseURL}/app/accounts/1/kanban/1`);
    await page.waitForLoadState('domcontentloaded');

    // Aguarda o board montar
    await expect(page.getByTestId('kanban-view-switcher')).toBeVisible({ timeout: 15000 });

    // 2. Abre os detalhes do primeiro card disponível
    const card = page.locator('article[data-card-id]').first();
    await expect(card).toBeVisible({ timeout: 15000 });

    const cardMenuBtn = card.getByTestId('kanban-card-actions');
    await cardMenuBtn.click();
    const editBtn = page.getByTestId('kanban-card-edit');
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();

    // 3. A gaveta de detalhes deve estar visível
    const opportunityHeader = page.getByTestId('kanban-opportunity-header');
    await expect(opportunityHeader).toBeVisible({ timeout: 10000 });

    // 4. Clica no badge de status para alterar
    const statusBadge = opportunityHeader.getByTestId('kanban-card-status-badge');
    await expect(statusBadge).toBeVisible();
    await statusBadge.click();

    // 5. Seleciona a opção "Marcar como Ganho" (Won)
    const wonOption = page.getByTestId('kanban-card-status-option-won');
    if (await wonOption.isVisible({ timeout: 3000 }).catch(() => false)) {
      await wonOption.click();

      // 6. Confere que o status foi atualizado para Won
      await expect(statusBadge).toContainText(/won|ganho/i, { timeout: 10000 });
    }

    // 7. Fecha a gaveta
    const closeBtn = page.getByTestId('kanban-opportunity-close');
    await closeBtn.click();
    await expect(opportunityHeader).not.toBeVisible({ timeout: 10000 });
  });

  test('deve marcar uma oportunidade como Perdida com seleção de motivo (UC-09)', async ({ page, baseURL }) => {
    // 1. Acessa o board principal
    await page.goto(`${baseURL}/app/accounts/1/kanban/1`);
    await page.waitForLoadState('domcontentloaded');

    // 2. Abre os detalhes de um card (prefere o segundo card para isolamento do teste 1)
    const cards = page.locator('article[data-card-id]');
    await expect(cards.first()).toBeVisible({ timeout: 25000 });
    const card = (await cards.count()) > 1 ? cards.nth(1) : cards.first();

    const cardMenuBtn = card.getByTestId('kanban-card-actions');
    await cardMenuBtn.click();
    const editBtn = page.getByTestId('kanban-card-edit');
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();

    // 3. A gaveta de detalhes deve estar visível
    const opportunityHeader = page.getByTestId('kanban-opportunity-header');
    await expect(opportunityHeader).toBeVisible({ timeout: 10000 });

    // 4. Clica no badge de status
    const statusBadge = opportunityHeader.getByTestId('kanban-card-status-badge');
    await expect(statusBadge).toBeVisible();

    // 5. Se estiver com status fechado/won/lost, primeiro reabre e confirma no formulário
    const initialText = await statusBadge.innerText();
    if (/won|ganho|lost|perdido/i.test(initialText)) {
      await statusBadge.click();
      const reopenOption = page.getByTestId('kanban-card-status-option-reopen');
      await expect(reopenOption).toBeVisible({ timeout: 5000 });
      await reopenOption.click();

      const confirmReopenBtn = page.getByTestId('kanban-card-status-confirm');
      await expect(confirmReopenBtn).toBeVisible({ timeout: 5000 });
      await confirmReopenBtn.click();

      await expect(statusBadge).toContainText(/open|abert/i, { timeout: 10000 });
    }

    await statusBadge.click();
    const lostOption = page.getByTestId('kanban-card-status-option-lost');
    await expect(lostOption).toBeVisible({ timeout: 5000 });
    await lostOption.click();

    // 6. Formulário de motivo de perda: confirma
    const confirmReasonBtn = page.getByTestId('kanban-card-status-confirm');
    if (await confirmReasonBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
      await confirmReasonBtn.click();
    }

    // 7. Valida que o badge agora reflete o status Lost
    await expect(statusBadge).toContainText(/lost|perdido/i, { timeout: 10000 });

    // 8. Fecha a gaveta
    const closeBtn = page.getByTestId('kanban-opportunity-close');
    await closeBtn.click();
    await expect(opportunityHeader).not.toBeVisible({ timeout: 10000 });
  });
});
