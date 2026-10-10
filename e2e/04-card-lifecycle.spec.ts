import { test, expect } from '@playwright/test';

test.describe('UC-04, UC-06 & UC-07: Customização de Estágios, Movimentação e Ciclo de Vida do Card', () => {
  test('deve adicionar uma nova etapa ao funil (UC-04)', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/app/accounts/1/kanban/1`);
    await page.waitForLoadState('domcontentloaded');

    // 1. Localiza o botão para abrir o rascunho de nova etapa
    const addStageBtn = page.getByTestId('kanban-create-stage-draft');
    await expect(addStageBtn).toBeVisible({ timeout: 25000 });
    await addStageBtn.click();

    // 2. Preenche o nome da nova etapa com identificador único
    const stageName = `Etapa ${Date.now()}`;
    const stageInput = page.getByTestId('kanban-new-stage-name-input');
    await expect(stageInput).toBeVisible({ timeout: 5000 });
    await stageInput.fill(stageName);

    // 3. Confirma a criação da etapa
    const confirmBtn = page.getByTestId('kanban-create-stage-confirm');
    await confirmBtn.click();

    // 4. A nova coluna deve ser renderizada no board
    await expect(page.locator('body')).toContainText(stageName, { timeout: 10000 });

    // 5. Localiza o primeiro card disponível no board
    const card = page.locator('article[data-card-id]').first();
    await expect(card).toBeVisible({ timeout: 15000 });

    // 6. Abre o menu de ações do card
    const cardMenuBtn = card.getByTestId('kanban-card-actions');
    await cardMenuBtn.click();

    // 7. Clica na opção "Move to"
    const moveOption = page.getByTestId('kanban-card-move');
    await expect(moveOption).toBeVisible({ timeout: 5000 });
    await moveOption.click();

    // 8. Seleciona o primeiro estágio de destino disponível no submenu
    const targetStageBtn = page.getByTestId('kanban-card-move-stage').first();
    await expect(targetStageBtn).toBeVisible({ timeout: 5000 });
    await targetStageBtn.click();

    // 9. Confirma se houver modal de confirmação
    const confirmMoveBtn = page.getByTestId('kanban-card-move-confirm-submit');
    if (await confirmMoveBtn.isVisible({ timeout: 1500 }).catch(() => false)) {
      await confirmMoveBtn.click();
    }

    // 10. Confere que a transição ocorreu com sucesso e aguarda o menu fechar
    await expect(moveOption).not.toBeVisible({ timeout: 5000 });
    await expect(page.locator('body')).not.toContainText('Error moving card');
  });

  test('deve abrir a gaveta de detalhes, adicionar nota e alterar prioridade (UC-07)', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/app/accounts/1/kanban/1`);
    await page.waitForLoadState('domcontentloaded');

    // Garante que o board montou completamente
    await expect(page.getByTestId('kanban-view-switcher')).toBeVisible({ timeout: 25000 });

    // 1. Localiza um card e abre a gaveta de detalhes via menu Editar
    const card = page.locator('article[data-card-id]').first();
    await expect(card).toBeVisible({ timeout: 15000 });

    const cardMenuBtn = card.getByTestId('kanban-card-actions');
    await cardMenuBtn.click();
    const editBtn = page.getByTestId('kanban-card-edit');
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();

    // 2. A gaveta lateral deve abrir
    const opportunityHeader = page.getByTestId('kanban-opportunity-header');
    await expect(opportunityHeader).toBeVisible({ timeout: 10000 });

    // 3. Acessa a aba de Atividade / Activity
    const activityTab = page.getByRole('button', { name: /activity|atividade/i });
    await expect(activityTab).toBeVisible({ timeout: 10000 });
    await activityTab.click();

    // 4. Escreve uma nota interna na timeline
    const noteText = `Nota E2E ${Date.now()}`;
    const noteInput = page.getByTestId('kanban-opportunity-note-input');
    await expect(noteInput).toBeVisible({ timeout: 10000 });
    await noteInput.fill(noteText);

    const submitNoteBtn = page.getByTestId('kanban-opportunity-note-submit');
    await expect(submitNoteBtn).toBeEnabled();
    await submitNoteBtn.click();

    // 5. A nota deve aparecer na timeline
    await expect(page.locator('body')).toContainText(noteText, { timeout: 15000 });

    // 6. Altera a prioridade do card
    const priorityMenu = page.getByTestId('kanban-opportunity-priority');
    await expect(priorityMenu).toBeVisible();
    await priorityMenu.click();

    const priorityOption = page.getByTestId('kanban-priority-option').filter({ hasText: /high|alta|urgent|urgente/i }).first();
    await expect(priorityOption).toBeVisible({ timeout: 5000 });
    await priorityOption.click();

    // 7. Fecha a gaveta
    const closeBtn = page.getByTestId('kanban-opportunity-close');
    await closeBtn.click();
    await expect(opportunityHeader).not.toBeVisible({ timeout: 10000 });
  });
});
