# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Busca de contatos (US07)", type: :request) do
  let(:user) { create_user }
  let(:other_user) { create_user }

  def login(usuario)
    post(entrar_path, params: { email: usuario.email, password: "123456" })
  end

  def busca(termo)
    get(contacts_path, params: { q: termo })
  end

  describe "GET /contacts?q=" do
    context "sem autenticação" do
      it "redireciona para o login" do
        create_contact(user, name: "João Silva")

        busca("joao")

        expect(response).to(redirect_to(entrar_url))
      end
    end

    context "com autenticação" do
      before do
        login(user)
        create_contact(user, name: "João Silva", phone: "(11) 98888-1234", email: "joao@exemplo.com")
        create_contact(user, name: "Maria Souza", phone: "(11) 98888-5678")
      end

      it "acha o contato buscando sem acento" do
        busca("joao")

        expect(response.body).to(include("João Silva"))
        expect(response.body).not_to(include("Maria Souza"))
      end

      it "acha o contato buscando com acento" do
        busca("João")

        expect(response.body).to(include("João Silva"))
      end

      it "acha o contato com erro de digitação" do
        create_contact(user, name: "Pedro Lima", phone: "(11) 98888-9999")

        busca("pedri")

        expect(response.body).to(include("Pedro Lima"))
      end

      it "encontra por telefone" do
        busca("5678")

        expect(response.body).to(include("Maria Souza"))
      end

      it "não devolve nada quando não há correspondente" do
        busca("ninguem")

        expect(response.body).not_to(include("João Silva"))
        expect(response.body).not_to(include("Maria Souza"))
      end

      it "mostra a listagem completa quando o termo é vazio" do
        busca("")

        expect(response.body).to(include("João Silva"))
        expect(response.body).to(include("Maria Souza"))
      end
    end

    context "isolamento por usuário" do
      it "não mostra contato de outra conta" do
        login(user)
        create_contact(user, name: "Silvia Zouza", phone: "(11) 90000-0001")
        create_contact(other_user, name: "Joana Pradp", phone: "(11) 90000-0002")

        busca("pradp")

        expect(response.body).not_to(include("Joana Pradp"))
      end
    end
  end
end
