# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Rodapé", type: :feature) do
  let(:user) { create_user }

  before do
    visit entrar_path
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "123456"
    click_on "Entrar"
  end

  it "exibe apenas links legítimos, sem mocks de newsletter ou redes sociais" do
    within("footer") do
      expect(page).to(have_content("Navegação"))
      expect(page).to(have_content("Conta"))
      expect(page).to(have_content("Todos os direitos reservados."))
      expect(page).to(have_no_text(/newsletter/i))
      expect(page).to(have_no_content("Inscrever-se"))
      expect(page).to(have_no_selector("input[type='email']"))
      expect(page).to(have_no_selector("a[href='#']"))
    end
  end

  it "permite sair pelo rodapé" do
    within("footer") { click_on "Sair" }

    expect(page).to(have_content("Logout realizado com sucesso!"))
    expect(page).to(have_link("Entrar"))
  end
end
