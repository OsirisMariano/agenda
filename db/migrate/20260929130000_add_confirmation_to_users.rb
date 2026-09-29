# frozen_string_literal: true

# Confirmação de e-mail no cadastro (US09, #32). As três colunas espelham o
# par `reset_digest`/`reset_sent_at` da recuperação de senha da US01, para os
# dois fluxos lerem igual.
class AddConfirmationToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column(:users, :confirmed_at, :datetime)
    add_column(:users, :confirmation_digest, :string)
    add_column(:users, :confirmation_sent_at, :datetime)

    # Contas que já existiam usavam o Agenda com o e-mail que informou, ou seja,
    # já provaram posse do endereço. Sem este backfill elas ficariam com
    # `confirmed_at` nulo e o gate de login trancaria todo mundo que já tinha
    # conta — o pior jeito de introduzir um recurso: quebrando o que funcionava.
    # A data usada é `created_at`, que é o que a conta valia quando nasceu.
    execute("UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL")
  end

  def down
    remove_column(:users, :confirmation_digest)
    remove_column(:users, :confirmation_sent_at)
    remove_column(:users, :confirmed_at)
  end
end
