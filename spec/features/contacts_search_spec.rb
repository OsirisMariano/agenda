# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Busca de contatos pela tela", type: :feature) do
  let(:user) { create_user }

  def entrar
    visit(entrar_path)
    fill_in("E-mail", with: user.email)
    fill_in("Senha", with: "123456")
    click_on("Entrar")
    click_on("Ver Meus Contatos")
  end

  before do
    create_contact(user, name: "João Silva", phone: "(11) 98888-1234", email: "joao@exemplo.com")
    create_contact(user, name: "Maria Souza", phone: "(11) 98888-5678")
  end

  it "acha o contato mesmo sem digitar o acento" do
    entrar
    fill_in "q", with: "joao"
    click_button "Buscar"

    expect(page).to(have_content("João Silva"))
    expect(page).not_to(have_content("Maria Souza"))
  end

  it "acha o contato com erro de digitação" do
    create_contact(user, name: "Pedro Lima", phone: "(11) 98888-9999")
    entrar
    fill_in "q", with: "pedri"
    click_button "Buscar"

    expect(page).to(have_content("Pedro Lima"))
  end

  it "avisa que a busca tolera acento quando não acha nada" do
    entrar
    fill_in "q", with: "ninguem"
    click_button "Buscar"

    expect(page).to(have_content("Nenhum resultado encontrado"))
    expect(page).to(have_content("sem acento"))
  end

  it "não mostra contato de outra conta" do
    other = create_user
    create_contact(other, name: "Joana Pradp", phone: "(11) 90000-0002")
    entrar
    fill_in "q", with: "pradp"
    click_button "Buscar"

    expect(page).not_to(have_content("Joana Pradp"))
  end
end
