import { test, expect } from '@playwright/test';

test.describe('Catálogo de Produtos e Itens no Card (UC-10)', () => {
  test('deve associar produto do catálogo a um card com cálculo automático de subtotal', async ({ page }) => {
    // 1. Acessa o board principal
    await page.goto('/app/accounts/1/kanban/1');
    await page.waitForLoadState('domcontentloaded');

    // Garante que o board montou completamente
    await expect(page.getByTestId('kanban-view-switcher')).toBeVisible({ timeout: 25000 });

    // 2. Localiza o primeiro card disponível no board
    const card = page.locator('article[data-card-id]').first();
    await expect(card).toBeVisible({ timeout: 15000 });

    // 3. Abre a gaveta de edição do card através do menu de ações
    const cardMenuBtn = card.getByTestId('kanban-card-actions');
    await cardMenuBtn.click();
    const editBtn = page.getByTestId('kanban-card-edit');
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();

    // 4. Valida a abertura do cabeçalho da oportunidade
    const opportunityHeader = page.getByTestId('kanban-opportunity-header');
    await expect(opportunityHeader).toBeVisible({ timeout: 10000 });

    // 5. Acessa a aba "Produtos" / "Products"
    const productsTab = page.getByRole('button', { name: /Products|Produtos|Itens/i });
    await expect(productsTab).toBeVisible({ timeout: 5000 });
    await productsTab.click();

    // 6. Valida a presença do container da aba de produtos
    const productsTabContainer = page.getByTestId('kanban-opportunity-products-tab');
    await expect(productsTabContainer).toBeVisible({ timeout: 5000 });

    // 7. Realiza a busca pelo produto cadastrado "Plano Pro"
    const searchInput = page.getByTestId('kanban-opportunity-product-search').locator('input');
    await expect(searchInput).toBeVisible();
    await searchInput.fill('Plano Pro');

    // 8. Aguarda a lista de resultados da busca
    const searchResults = page.getByTestId('kanban-opportunity-product-search-results');
    await expect(searchResults).toBeVisible({ timeout: 10000 });
    await expect(searchResults.getByText('Plano Pro Anual')).toBeVisible();

    // 9. Clica no botão para expandir o formulário de adição
    const addToggle = page.getByTestId('kanban-opportunity-product-add-toggle').first();
    await expect(addToggle).toBeVisible();
    await addToggle.click();

    // 10. Define a quantidade desejada como 2
    const quantityInput = page.getByTestId('kanban-opportunity-product-add-quantity');
    await expect(quantityInput).toBeVisible();
    await quantityInput.fill('2');

    // 11. Confirma a adição do produto ao card
    const confirmButton = page.getByTestId('kanban-opportunity-product-add-confirm');
    await expect(confirmButton).toBeVisible();
    await confirmButton.click();

    // 12. Valida que o produto foi vinculado e exibido na tabela de itens
    const linkedProducts = page.getByTestId('kanban-opportunity-linked-products');
    await expect(linkedProducts).toBeVisible({ timeout: 10000 });
    await expect(linkedProducts.getByText('Plano Pro Anual').first()).toBeVisible();

    // 13. Valida o subtotal calculado (2 x R$ 1.200,00 = R$ 2.400,00)
    await expect(linkedProducts.getByText(/2\.400,00|2400/).first()).toBeVisible();
  });
});
