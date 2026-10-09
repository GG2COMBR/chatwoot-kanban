# reconcile_migrations.rb
#
# Corrige o efeito colateral de instalar o pacote num banco criado via
# `db:chatwoot_prepare` (que usa db:schema:load). O schema:load marca como
# aplicadas todas as migrations com data anterior à do schema — incluindo as
# migrations do Kanban, cujas tabelas NÃO existem ainda. Este script remove
# esses registros "fantasma" do schema_migrations para que `db:migrate` as
# execute de verdade e crie as tabelas.
#
# Uso (no ambiente do Chatwoot, após install.sh e antes de db:migrate):
#   bundle exec rails runner reconcile_migrations.rb
#
# É idempotente e seguro: só remove registros de migrations do Kanban cuja
# tabela-alvo ainda não existe.

conn = ActiveRecord::Base.connection

kanban_versions = Dir.glob(Rails.root.join('db/migrate/*kanban*'))
                     .map { |f| File.basename(f).split('_').first }

applied = conn.select_values('SELECT version FROM schema_migrations')
kanban_boards_exists = conn.table_exists?('kanban_boards')

if kanban_boards_exists
  puts 'Tabelas kanban já existem; nada a reconciliar.'
else
  to_unmark = kanban_versions & applied
  to_unmark.each do |v|
    conn.execute("DELETE FROM schema_migrations WHERE version = '#{v}'")
  end
  puts "Reconciliado: #{to_unmark.size} migration(s) do Kanban desmarcada(s)."
  puts 'Agora rode: bundle exec rails db:migrate'
end
