# scripts/seed-e2e.rb
#
# Seed idempotente para os testes E2E Playwright do chatwoot-kanban.
# Prepara a conta, usuário admin, inbox, contato, conversa, funil e produtos.
#
# Uso:
#   bundle exec rails runner scripts/seed-e2e.rb
#

account = Account.find_or_create_by!(id: 1) do |a|
  a.name = 'Acme Inc'
  a.locale = 'pt_BR'
end
account.enable_features('kanban', 'kanban_products')
account.save!

user = User.find_or_initialize_by(email: 'admin@kanban.test')
user.name = 'Admin Test'
user.password = 'Password123!'
user.password_confirmation = 'Password123!'
user.confirmed_at ||= Time.current
user.save!

AccountUser.find_or_create_by!(account: account, user: user) do |au|
  au.role = :administrator
end

inbox = account.inboxes.first || account.inboxes.create!(
  name: 'Acme Support',
  channel: Channel::WebWidget.create!(account: account, website_url: 'https://acme.inc')
)

contact = account.contacts.find_or_create_by!(email: 'cliente@exemplo.com') do |c|
  c.name = 'Cliente Exemplo'
  c.phone_number = '+5511999999999'
end

contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |ci|
  ci.source_id = 'cliente-exemplo-source'
end

conversation = account.conversations.first || account.conversations.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open
)

board = KanbanBoard.find_or_create_by!(account: account, name: 'Pipeline de Vendas') do |b|
  b.enable_products = true
  b.show_monetary_values = true
end

s_inbox = board.kanban_stages.find_or_create_by!(name: 'Inbox') do |s|
  s.position = 1
  s.account = account
end
s_negotiating = board.kanban_stages.find_or_create_by!(name: 'Em Negociação') do |s|
  s.position = 2
  s.account = account
end
s_won = board.kanban_stages.find_or_create_by!(name: 'Won') do |s|
  s.position = 3
  s.account = account
end
s_lost = board.kanban_stages.find_or_create_by!(name: 'Lost') do |s|
  s.position = 4
  s.account = account
end

board.update!(
  won_stage_id: s_won.id,
  lost_stage_id: s_lost.id,
  lost_reason_required: true,
  enable_products: true,
  show_monetary_values: true
)

board.kanban_reasons.find_or_create_by!(title: 'Preço elevado') do |r|
  r.account = account
  r.reason_type = :lost
end

board.kanban_reasons.find_or_create_by!(title: 'Fechou com concorrente') do |r|
  r.account = account
  r.reason_type = :lost
end

card = board.kanban_cards.first || board.kanban_cards.create!(
  account: account,
  kanban_stage: s_inbox,
  inbox: inbox,
  conversation: conversation,
  contact: contact,
  subject: 'Oportunidade de Consultoria E2E',
  origin: :conversation,
  position: 1000
)

KanbanProduct.find_or_create_by!(account: account, sku: 'PRO-ANUAL') do |p|
  p.title = 'Plano Pro Anual'
  p.price = 1200.00
  p.category = 'Planos'
  p.active = true
end

puts '=================================================='
puts '✔ Seed E2E do Kanban preparado com sucesso!'
puts "  Conta: ##{account.id} (#{account.name})"
puts "  Usuário: #{user.email} (Admin)"
puts "  Funil: ##{board.id} (#{board.name}) com #{board.kanban_stages.count} etapas"
puts "  Produtos: #{KanbanProduct.count} cadastrado(s)"
puts '=================================================='
