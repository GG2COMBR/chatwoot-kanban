import { test, expect } from '@playwright/test';

test.describe('UC-03 & UC-04: Gestão de Pipelines (Boards & Estágios)', () => {
  test('deve criar um pipeline instantâneo com template "Sales" e abrir as colunas de estágios', async ({ page, baseURL }) => {
    // 1. Acessa a tela geral de Kanban
    await page.goto(`${baseURL}/app/accounts/1/kanban`);
    await page.waitForLoadState('domcontentloaded');

    // 2. O botão de criar pipeline deve estar visível para o admin
    const createBtn = page.getByTestId('overview-create-board-button');
    await expect(createBtn).toBeVisible({ timeout: 25000 });

    // 3. Clica no botão e navega para /app/accounts/1/kanban/new
    await createBtn.click();
    await page.waitForURL(/\/app\/accounts\/1\/kanban\/new/);

    // 4. Deve exibir o seletor de templates
    const templatePicker = page.getByTestId('kanban-board-template-picker');
    await expect(templatePicker).toBeVisible({ timeout: 15000 });

    // 5. Clica no template "Vendas" (Sales)
    const salesTemplate = page.getByTestId('kanban-board-template-sales');
    await expect(salesTemplate).toBeVisible({ timeout: 15000 });
    await salesTemplate.click();

    // Se o nome sugerido já existir, o modal de nome é aberto; se não, cria direto:
    const nameModal = page.getByTestId('kanban-board-create-name-modal');
    if (await nameModal.isVisible({ timeout: 2000 }).catch(() => false)) {
      const uniqueName = `Vendas ${Date.now()}`;
      await page.getByTestId('kanban-board-create-name-input').fill(uniqueName);
      await page.getByTestId('kanban-board-create-name-confirm').click();
    }

    // 6. Deve redirecionar para a visualização do board criado (/app/accounts/1/kanban/:boardId)
    await page.waitForURL(/\/app\/accounts\/1\/kanban\/\d+/, { timeout: 20000 });

    // 7. Valida que o board carregou com suas colunas de estágios
    const addCardButtons = page.locator('text=/Add new card|Adicionar card/i');
    await expect(addCardButtons.first()).toBeVisible({ timeout: 15000 });
  });

  test('deve criar um pipeline personalizado usando template "Blank" com nome customizado', async ({ page, baseURL }) => {
    const customBoardName = `Pipeline Suporte ${Date.now()}`;

    // 1. Acessa a rota de novo board diretamente
    await page.goto(`${baseURL}/app/accounts/1/kanban/new`);
    await page.waitForLoadState('domcontentloaded');

    // 2. Seleciona o template em branco (Blank sempre exige nome customizado)
    const blankTemplate = page.getByTestId('kanban-board-template-blank');
    await expect(blankTemplate).toBeVisible({ timeout: 25000 });
    await blankTemplate.click();

    // 3. O modal de nome abre obrigatoriamente para o template blank
    const nameModal = page.getByTestId('kanban-board-create-name-modal');
    await expect(nameModal).toBeVisible();

    // 4. Preenche o nome personalizado
    const nameInput = page.getByTestId('kanban-board-create-name-input');
    await nameInput.fill(customBoardName);

    // 5. Confirma a criação
    const confirmBtn = page.getByTestId('kanban-board-create-name-confirm');
    await confirmBtn.click();

    // 6. Redireciona para o novo board
    await page.waitForURL(/\/app\/accounts\/1\/kanban\/\d+/, { timeout: 15000 });

    // 7. O cabeçalho deve exibir o nome personalizado
    await expect(page.locator('body')).toContainText(customBoardName);
  });
});
