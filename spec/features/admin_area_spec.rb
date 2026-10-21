# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Área admin", type: :feature) do
  let(:admin) { create_user(admin: true) }

  def entrar_como(user)
    visit(entrar_path)
    fill_in("E-mail", with: user.email)
    fill_in("Senha", with: "123456")
    click_on("Entrar")
  end

  context "casca admin (US1)" do
    before { entrar_como(admin) }

    it "renderiza /usuarios dentro da casca com sidebar e topbar" do
      visit "/usuarios"

      expect(page).to(have_http_status(:success))
      within("nav.admin-sidebar") do
        expect(page).to(have_content("Agenda"))
        expect(page).to(have_link("Visão Geral"))
        expect(page).to(have_link("Usuários"))
      end
      expect(page).to(have_selector(".admin-topbar"))
    end

    it "destaca o item de navegação da página corrente" do
      visit "/usuarios"

      within("nav.admin-sidebar") do
        expect(page).to(have_selector("a.active", text: "Usuários"))
      end
    end

    it "exibe o breadcrumb da página no topbar" do
      visit "/usuarios"

      within(".admin-topbar") do
        expect(page).to(have_selector(".breadcrumb"))
        expect(page).to(have_content("Admin"))
        expect(page).to(have_content("Usuários"))
      end
    end

    it "mantém o rodapé público na casca" do
      visit "/usuarios"

      within("footer") do
        expect(page).to(have_content("Navegação"))
        expect(page).to(have_content("Conta"))
        expect(page).to(have_content("Todos os direitos reservados."))
      end
    end

    it "oferece o controle de recolher a sidebar sem depender de JavaScript" do
      visit "/usuarios"

      expect(page).to(have_selector("input#admin-sidebar-toggle", visible: :all))
      expect(page).to(have_selector("label[for='admin-sidebar-toggle']"))
    end
  end

  context "dashboard /admin (US2)" do
    before { entrar_como(admin) }

    it "exibe os números e o atalho para a listagem de usuários" do
      outro = create_user
      create_contact(admin)
      create_contact(outro)

      visit "/admin"

      expect(page).to(have_http_status(:success))
      expect(page).to(have_content("Usuários cadastrados"))
      expect(page).to(have_content("Contatos totais"))
      expect(page).to(have_content("Contatos por semana"))
      expect(page).to(have_content("8 semanas"))
      within("nav.admin-sidebar") do
        expect(page).to(have_selector("a.active", text: "Visão Geral"))
      end
      expect(page).to(have_link("Usuários"))
    end

    it "carrega com zeros quando não há contatos" do
      visit "/admin"

      expect(page).to(have_http_status(:success))
      expect(page).to(have_content("Usuários cadastrados"))
      expect(page).to(have_content("Contatos por semana"))
    end

    it "redireciona usuário comum sem exibir números administrativos" do
      sair = create_user
      entrar_como(sair)

      visit "/admin"

      expect(page).to(have_content("Acesso negado."))
      expect(page).to(have_no_content("Contatos por semana"))
    end
  end

  context "link Admin na navbar (US3)" do
    it "aparece para o admin e leva à área admin" do
      entrar_como(admin)

      click_on("Admin")

      expect(page).to(have_selector(".admin-topbar"))
      expect(page).to(have_content("Usuários cadastrados"))
    end

    it "não aparece para usuário comum" do
      entrar_como(create_user)

      expect(page).to(have_no_link("Admin"))
    end

    it "não aparece para visitante" do
      visit root_path

      expect(page).to(have_no_link("Admin"))
    end
  end
end
