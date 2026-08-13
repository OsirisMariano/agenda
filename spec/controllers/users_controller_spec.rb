# frozen_string_literal: true

require "rails_helper"

RSpec.describe(UsersController, type: :controller) do
  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to(have_http_status(:success))
    end
  end

  describe "POST #create" do
    context "com dados válidos" do
      it "cria o usuário, faz login e redireciona" do
        expect do
          post(
            :create,
            params: {
              user: {
                name: "Novo",
                email: "novo@exemplo.com",
                password: "123456",
                password_confirmation: "123456",
              },
            },
          )
        end.to(change(User, :count).by(1))

        expect(session[:user_id]).to(eq(User.last.id))
        expect(response).to(redirect_to(root_path))
      end
    end

    context "com dados inválidos" do
      it "re-renderiza o formulário de cadastro" do
        post :create, params: { user: { name: "", email: "x", password: "123" } }
        expect(response).to(have_http_status(:unprocessable_entity))
      end
    end
  end

  describe "GET #index" do
    context "como admin" do
      it "lista os usuários" do
        admin = create_user(admin: true)
        session[:user_id] = admin.id

        get :index

        expect(response).to(have_http_status(:success))
      end
    end

    context "como usuário comum" do
      it "redireciona para a home com aviso" do
        session[:user_id] = create_user.id

        get :index

        expect(response).to(redirect_to(root_path))
      end
    end

    context "sem autenticação" do
      it "redireciona para a home" do
        get :index

        expect(response).to(redirect_to(root_path))
      end
    end
  end
end
