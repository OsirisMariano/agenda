# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Recuperação de senha", type: :feature) do
  let(:user) { create_user(email: "recupera@exemplo.com") }

  before { ActionMailer::Base.deliveries.clear }

  it "mostra o link 'Esqueci minha senha?' na tela de login" do
    visit entrar_path

    expect(page).to(have_link("Esqueci minha senha?", href: recuperar_senha_path))
  end

  it "solicita a redefinição e mostra a mensagem genérica" do
    visit recuperar_senha_path
    fill_in "E-mail", with: "recupera@exemplo.com"
    click_on "Enviar link de recuperação"

    expect(page).to(have_content("Se este e-mail existir em nosso sistema, enviaremos um link de recuperação."))
  end

  it "redefine a senha pelo link do e-mail e faz login com a nova senha" do
    visit recuperar_senha_path
    fill_in "E-mail", with: "recupera@exemplo.com"
    click_on "Enviar link de recuperação"

    user.create_reset_digest
    visit edit_recuperar_senha_path(token: user.reset_token, email: user.email)

    fill_in "Nova senha", with: "nova-senha"
    fill_in "Confirmar nova senha", with: "nova-senha"
    click_on "Redefinir senha"

    expect(page).to(have_content("Senha redefinida com sucesso!"))

    fill_in "E-mail", with: "recupera@exemplo.com"
    fill_in "Senha", with: "nova-senha"
    click_on "Entrar"

    expect(page).to(have_content("Login realizado com sucesso!"))
    expect(page).to(have_content(user.name))
  end
end
