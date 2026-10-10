import { test as setup, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const authFile = 'e2e/.auth/user.json';

setup('authenticate as admin', async ({ page, baseURL }) => {
  const dir = path.dirname(authFile);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  // 1. Acessa a página de login
  await page.goto(`${baseURL}/app/login`);
  await expect(page).toHaveTitle(/Chatwoot/i);

  // 2. Preenche os campos de credenciais
  const emailInput = page.getByPlaceholder('example@companyname.com');
  const passwordInput = page.getByPlaceholder('Password', { exact: true });
  const submitButton = page.getByRole('button', { name: 'Login', exact: true });

  await emailInput.fill('admin@kanban.test');
  await passwordInput.fill('Password123!');
  await submitButton.click();

  // 3. Se atingir o limite de sessões ativas do Chatwoot, clica em "End all sessions"
  const endAllButton = page.getByRole('button', { name: /End all sessions|Encerrar todas as sessões/i });
  try {
    await endAllButton.waitFor({ state: 'visible', timeout: 3000 });
    await endAllButton.click();
  } catch {
    // Não apareceu, segue normalmente
  }

  // 4. Aguarda redirecionamento para o dashboard
  await page.waitForURL(/\/app\/accounts\/\d+/, { timeout: 20000 });

  // 5. Salva o storageState com cookies e tokens
  await page.context().storageState({ path: authFile });
});
