# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Contatos", type: :feature) do
  let(:user) { create_user }

  before do
    create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")
  end

  it "lista apenas os contatos do usuário e cria um novo" do
    other = create_user
    create_contact(other, name: "Contato de Outro")

    visit entrar_path
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "123456"
    click_on "Entrar"
    click_on "Ver Meus Contatos"

    expect(page).to(have_content("Ana Silva"))
    expect(page).not_to(have_content("Contato de Outro"))

    click_on "Novo Contato", match: :first
    fill_in "Nome", with: "Bruno Costa"
    fill_in "Telefone", with: "(11) 97777-1234"
    click_on "Criar Contato"

    expect(page).to(have_content("Contato criado com sucesso!"))
    expect(page).to(have_content("Bruno Costa"))
  end

  it "cria um contato com e-mail, endereço e notas e mostra os detalhes" do
    visit entrar_path
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "123456"
    click_on "Entrar"
    click_on "Ver Meus Contatos"

    click_on "Novo Contato", match: :first
    fill_in "Nome", with: "Carla Dias"
    fill_in "Telefone", with: "(11) 97777-4321"
    fill_in "E-mail", with: "carla@exemplo.com"
    fill_in "Endereço", with: "Rua dos Ipês, 50"
    fill_in "Notas", with: "Colega do trabalho"
    click_on "Criar Contato"

    expect(page).to(have_content("Contato criado com sucesso!"))
    click_on "Carla Dias"
    expect(page).to(have_content("carla@exemplo.com"))
    expect(page).to(have_content("Rua dos Ipês, 50"))
    expect(page).to(have_content("Colega do trabalho"))
  end

  it "mostra paginação quando há mais de 12 contatos" do
    13.times do
      create_contact(user)
    end

    visit entrar_path
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "123456"
    click_on "Entrar"
    click_on "Ver Meus Contatos"

    expect(page).to(have_selector(".pagination"))
  end
end
