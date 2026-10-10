import { test, expect } from '@playwright/test';

test.describe('UC-05 & UC-06: Criação Manual de Oportunidades & Gestão de Cards', () => {
  test('deve abrir o painel de criação, buscar contato e criar um card no funil', async ({ page, baseURL }) => {
    // 1. Acessa o primeiro funil criado
    await page.goto(`${baseURL}/app/accounts/1/kanban/1`);
    await page.waitForURL(/\/app\/accounts\/1\/kanban\/\d+/);

    // 2. Localiza o botão de adicionar card do primeiro estágio (vazio ou com cards)
    const addCardBtn = page.getByTestId('kanban-empty-stage-add-card').or(page.getByTestId('kanban-stage-add-card')).first();
    await expect(addCardBtn).toBeVisible({ timeout: 10000 });
    await addCardBtn.click();

    // 3. O painel de criação de card deve abrir
    const panel = page.getByTestId('kanban-add-item-panel');
    await expect(panel).toBeVisible({ timeout: 10000 });

    // 4. Busca o contato de teste criado no seed
    const contactInput = page.getByRole('searchbox', { name: /search contacts/i }).or(page.getByPlaceholder(/name, phone, or email/i));
    await contactInput.fill('Cliente Exemplo');

    // 5. Clica no resultado da busca de contato
    const contactResult = page.getByTestId('kanban-contact-search-results').locator('button, [role="button"]').first();
    await expect(contactResult).toBeVisible({ timeout: 10000 });
    await contactResult.click();

    // 6. Passo da conversa: seleciona a conversa do contato
    const conversationItem = page.getByTestId('kanban-conversation-list').locator('button, [role="button"]').first();
    await expect(conversationItem).toBeVisible({ timeout: 10000 });
    await conversationItem.click();

    // 7. Passo do card: preenche o assunto do card de forma única
    const cardSubject = `Oportunidade E2E ${Date.now()}`;
    const subjectInput = page.getByTestId('kanban-manual-card-subject').or(page.getByPlaceholder(/Exchange negotiation/i));
    await expect(subjectInput).toBeVisible({ timeout: 10000 });
    await subjectInput.fill(cardSubject);

    // 8. Submete a criação do card
    const submitBtn = page.getByTestId('kanban-manual-card-submit').or(page.getByRole('button', { name: /create card|criar/i }));
    await expect(submitBtn).toBeEnabled({ timeout: 10000 });
    await submitBtn.click();

    // 9. O card deve aparecer na coluna do funil
    await expect(page.locator('body')).toContainText(cardSubject, { timeout: 15000 });
  });
});
