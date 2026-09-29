# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Autenticação", type: :feature) do
  it "permite cadastrar, confirmar o e-mail, fazer login e sair" do
    visit root_path
    click_on "Cadastre-se Grátis"

    fill_in "Nome", with: "Novo Usuário"
    fill_in "E-mail", with: "novo@exemplo.com"
    fill_in "Senha", with: "123456"
    fill_in "Confirmar Senha", with: "123456"
    click_on "Criar Conta"

    user = User.find_by(email: "novo@exemplo.com")
    expect(user).to(be_present)
    expect(page).to(have_content("Confira seu e-mail"))

    # US09: a conta existe mas ainda não entra no sistema.
    user.create_confirmation_digest
    visit confirmar_email_path(email: user.email, token: user.confirmation_token)

    expect(page).to(have_content("E-mail confirmado com sucesso!"))

    visit entrar_path
    fill_in "E-mail", with: "novo@exemplo.com"
    fill_in "Senha", with: "123456"
    click_on "Entrar"

    expect(page).to(have_content("Ver Meus Contatos"))

    within(".dropdown-menu") { click_on "Sair" }
    expect(page).to(have_content("Entrar"))
    expect(page).to(have_content("Cadastre-se Grátis"))
  end

  it "faz login com e-mail e senha corretos" do
    create_user(name: "Usuário Teste", email: "login@exemplo.com")

    visit entrar_path
    fill_in "E-mail", with: "login@exemplo.com"
    fill_in "Senha", with: "123456"
    click_on "Entrar"

    expect(page).to(have_content("Usuário Teste"))
  end

  it "mostra erro com credenciais inválidas" do
    visit entrar_path
    fill_in "E-mail", with: "naoexiste@exemplo.com"
    fill_in "Senha", with: "123456"
    click_on "Entrar"

    expect(page).to(have_content("E-mail ou senha inválidos"))
  end
end
