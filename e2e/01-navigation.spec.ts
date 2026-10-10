import { test, expect } from '@playwright/test';

test.describe('UC-01 & UC-02: Autenticação & Navegação no Módulo Kanban', () => {
  test('deve exibir o item Kanban no menu lateral e abrir o painel', async ({ page, baseURL }) => {
    // Acessa o dashboard da conta com a sessão admin já autenticada
    await page.goto(`${baseURL}/app/accounts/1/dashboard`);

    // Aguarda o painel principal carregar
    await expect(page).toHaveTitle(/Chatwoot/i);

    // O link do Kanban deve estar visível no menu lateral
    const kanbanNavLink = page.locator('a[href*="/kanban"]').first();
    await expect(kanbanNavLink).toBeVisible({ timeout: 20000 });

    // Clica no link e navega para /app/accounts/1/kanban
    await kanbanNavLink.click();
    await page.waitForURL(/\/app\/accounts\/1\/kanban/, { timeout: 10000 });

    // Verifica que a tela do Kanban renderizou
    await expect(page.locator('body')).not.toContainText('You are not authorized to do this action');
  });

  test('deve acessar a rota direta do Kanban com sucesso', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/app/accounts/1/kanban`);
    await expect(page).toHaveURL(/\/app\/accounts\/1\/kanban/);

    // Deve renderizar elementos da página (ex: seletor de funis ou botão de novo funil)
    const content = page.locator('main').first();
    await expect(content).toBeVisible();
  });
});
