# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ContactsController, type: :controller) do
  let(:user) { create_user }
  let(:other_user) { create_user }

  before { session[:user_id] = user.id }

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to(have_http_status(:success))
    end

    it "lista apenas os contatos do usuário logado" do
      mine = create_contact(user)
      other = create_contact(other_user)

      get :index

      expect(assigns(:contacts)).to(include(mine))
      expect(assigns(:contacts)).not_to(include(other))
    end

    it "pagina os contatos" do
      15.times { create_contact(user) }

      get :index

      expect(assigns(:pagy)).to(be_a(Pagy))
      expect(assigns(:contacts).size).to(eq(12))
      expect(assigns(:pagy).count).to(eq(15))
    end

    it "filtra pela busca" do
      create_contact(user, name: "Ana Silva")
      create_contact(user, name: "Bruno Costa")

      get :index, params: { q: "Silva" }

      expect(assigns(:contacts).map(&:name)).to(contain_exactly("Ana Silva"))
    end
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to(have_http_status(:success))
    end
  end

  describe "POST #create" do
    context "com dados válidos" do
      it "cria o contato do usuário e redireciona" do
        expect do
          post(:create, params: { contact: { name: "Novo Contato", phone: "(11) 97777-1234" } })
        end.to(change { user.contacts.count }.by(1))

        expect(response).to(redirect_to(contacts_path))
      end
    end

    context "com dados inválidos" do
      it "re-renderiza a página de criação" do
        post :create, params: { contact: { name: "", phone: "" } }
        expect(response).to(have_http_status(:unprocessable_entity))
      end
    end
  end

  describe "PATCH #update" do
    let(:contact) { create_contact(user) }

    context "com dados válidos" do
      it "atualiza o contato e redireciona" do
        patch :update, params: { id: contact.id, contact: { name: "Nome Atualizado" } }
        expect(contact.reload.name).to(eq("Nome Atualizado"))
        expect(response).to(redirect_to(contacts_path))
      end
    end

    context "com dados inválidos" do
      it "re-renderiza a página de edição" do
        patch :update, params: { id: contact.id, contact: { name: "" } }
        expect(response).to(have_http_status(:unprocessable_entity))
      end
    end
  end

  describe "DELETE #destroy" do
    it "exclui o contato e redireciona" do
      contact = create_contact(user)

      expect { delete(:destroy, params: { id: contact.id }) }.to(change { user.contacts.count }.by(-1))
      expect(response).to(redirect_to(contacts_path))
    end
  end

  describe "autorização" do
    it "não permite acessar o contato de outro usuário" do
      other = create_contact(other_user)

      expect { get(:edit, params: { id: other.id }) }.to(raise_error(ActiveRecord::RecordNotFound))
      expect { delete(:destroy, params: { id: other.id }) }.to(raise_error(ActiveRecord::RecordNotFound))
    end

    it "redireciona para login quando não autenticado" do
      session[:user_id] = nil

      get :index

      expect(response).to(redirect_to("/entrar"))
    end
  end
end
