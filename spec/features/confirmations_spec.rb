# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Confirmação de e-mail pela tela", type: :feature) do
  let(:user) { create_user(confirmed_at: nil, email: "novo-confirmar@exemplo.com") }

  it "exige confirmar o e-mail depois do cadastro" do
    visit root_path
    click_on "Cadastre-se Grátis"

    fill_in "Nome", with: "Novo Usuário"
    fill_in "E-mail", with: "sem-confirmar@exemplo.com"
    fill_in "Senha", with: "123456"
    fill_in "Confirmar Senha", with: "123456"
    click_on "Criar Conta"

    expect(page).to(have_content("Confira seu e-mail"))
    expect(page).to(have_content("Entrar"))
    expect(page).not_to(have_content("Ver Meus Contatos"))

    fill_in "E-mail", with: "sem-confirmar@exemplo.com"
    fill_in "Senha", with: "123456"
    click_on "Entrar"

    expect(page).to(have_content("Confirme seu e-mail antes de entrar."))
    expect(page).not_to(have_content("Ver Meus Contatos"))
  end

  it "libera o acesso depois de confirmar pelo link" do
    user.create_confirmation_digest
    visit confirmar_email_path(email: user.email, token: user.confirmation_token)

    expect(page).to(have_content("E-mail confirmado com sucesso!"))

    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "123456"
    click_on "Entrar"

    expect(page).to(have_content("Ver Meus Contatos"))
  end

  it "avisa e volta ao login quando o link expirou" do
    user.create_confirmation_digest
    token = user.confirmation_token
    user.update!(confirmation_sent_at: 3.hours.ago)

    visit confirmar_email_path(email: user.email, token: token)

    expect(page).to(have_content("Link de confirmação inválido, expirado ou já utilizado."))
    expect(user.reload).not_to(be_confirmed)
  end

  it "reenvia a confirmação a partir da tela de login" do
    user.create_confirmation_digest
    antigo = user.reload.confirmation_digest

    visit reenviar_confirmacao_path
    fill_in "E-mail", with: user.email
    click_on "Reenviar e-mail"

    expect(page).to(have_content("Se este e-mail existir e não estiver confirmado"))
    expect(user.reload.confirmation_digest).not_to(eq(antigo))
    expect(ActionMailer::Base.deliveries.count).to(eq(1))
  end

  it "não entrega o link pelo formulário de reenvio" do
    visit reenviar_confirmacao_path
    fill_in "E-mail", with: "ninguem@exemplo.com"
    click_on "Reenviar e-mail"

    expect(page).to(have_content("Se este e-mail existir e não estiver confirmado"))
    expect(ActionMailer::Base.deliveries).to(be_empty)
  end

  it "rejeita o mesmo link usado duas vezes" do
    user.create_confirmation_digest
    token = user.confirmation_token
    visit confirmar_email_path(email: user.email, token: token)
    visit confirmar_email_path(email: user.email, token: token)

    expect(page).to(have_content("Link de confirmação inválido, expirado ou já utilizado."))
  end
end
