import { test, expect } from '@playwright/test';

test.describe('Relatórios e Dashboards de Performance (UC-12)', () => {
  test('deve acessar o Dashboard do Funil via View Switcher e exibir métricas e gráficos', async ({ page }) => {
    // 1. Acessa o board principal
    await page.goto('/app/accounts/1/kanban/1');
    await page.waitForLoadState('domcontentloaded');

    // 2. Abre o seletor de visualizações e clica em "Dashboard"
    const viewSwitcher = page.getByTestId('kanban-view-switcher');
    await expect(viewSwitcher).toBeVisible({ timeout: 25000 });
    await viewSwitcher.click();

    const dashboardOption = page.getByTestId('kanban-view-switcher-dashboard');
    await expect(dashboardOption).toBeVisible();
    await dashboardOption.click();

    // 3. Valida que a URL mudou para a rota do dashboard do board
    await page.waitForURL(/\/app\/accounts\/1\/kanban\/1\/dashboard/, { timeout: 10000 });

    // 4. Valida a presença do container principal do dashboard
    const dashboardContainer = page.getByTestId('kanban-dashboard');
    await expect(dashboardContainer).toBeVisible({ timeout: 10000 });

    // 5. Verifica os cartões de métricas do dashboard
    const openMetrics = page.getByText(/Leads in funnel|Oportunidades em Aberto|Total open value|Valor em aberto/i).first();
    await expect(openMetrics).toBeVisible();

    // 6. Verifica a presença das seções de gráficos nativos
    const wonLostHeading = page.getByRole('heading', { name: /Won vs Lost|Ganhos vs Perdidos/i });
    await expect(wonLostHeading).toBeVisible();

    const originHeading = page.getByRole('heading', { name: /Lead origin|Origem dos leads/i });
    await expect(originHeading).toBeVisible();

    const funnelHeading = page.getByRole('heading', { name: /Funnel by stage|Funil por estágio/i });
    await expect(funnelHeading).toBeVisible();
  });

  test('deve carregar os Relatórios Gerais do Kanban na rota de relatórios da conta', async ({ page }) => {
    // 1. Navega para a rota de relatórios kanban (/app/accounts/1/reports/kanban)
    await page.goto('/app/accounts/1/reports/kanban');
    await page.waitForLoadState('domcontentloaded');

    // 2. Valida o cabeçalho de relatórios kanban
    await expect(
      page.getByText(/Kanban reports|Relatórios do Kanban/i).first()
    ).toBeVisible({ timeout: 15000 });

    // 3. Valida que o filtro de funil/board está visível
    const boardFilterButton = page.getByRole('button', { name: /Pipeline de Vendas|Funil de Vendas|Board/i });
    await expect(boardFilterButton).toBeVisible({ timeout: 10000 });

    // 4. Valida os cartões de métricas de resumo
    await expect(
      page.getByRole('heading', { name: /Open cards|Cards em aberto|Abertos/i })
    ).toBeVisible();
    await expect(
      page.getByRole('heading', { name: /Won cards|Cards ganhos|Ganhos/i })
    ).toBeVisible();
  });
});
