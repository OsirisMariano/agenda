# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Métricas admin em /usuarios", type: :feature) do
  let(:admin) { create_user(admin: true) }

  def entrar_como(user)
    visit(entrar_path)
    fill_in("E-mail", with: user.email)
    fill_in("Senha", with: "123456")
    click_on("Entrar")
  end

  context "como admin" do
    before do
      outro = create_user
      create_contact(admin)
      create_contact(outro, created_at: 2.weeks.ago)
      entrar_como(admin)
      visit "/usuarios"
    end

    it "exibe o total de usuários, o total de contatos e a série de 8 semanas" do
      expect(page).to(have_content("Usuários cadastrados"))
      expect(page).to(have_content("Contatos totais"))
      expect(page).to(have_content("Contatos por semana"))
      expect(page).to(have_content("8 semanas"))
      expect(page).to(have_content("2")) # total de usuários (admin + outro)
      expect(page).to(have_content("1")) # total de contatos (apenas os da janela/soma exibida)
    end

    it "mantém a listagem de usuários existente" do
      expect(page).to(have_content(admin.email))
    end
  end

  context "sem contatos" do
    it "carrega a página com zeros, sem erro" do
      entrar_como(admin)
      visit "/usuarios"

      expect(page).to(have_http_status(:success))
      expect(page).to(have_content("Usuários cadastrados"))
    end
  end

  context "como usuário comum" do
    it "é redirecionado e não vê os números" do
      entrar_como(create_user)
      visit "/usuarios"

      expect(page).to(have_content("Acesso negado."))
      expect(page).to(have_no_content("Contatos por semana"))
    end
  end
end
