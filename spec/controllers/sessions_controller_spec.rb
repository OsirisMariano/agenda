# frozen_string_literal: true

require "rails_helper"

RSpec.describe(SessionsController, type: :controller) do
  let(:user) { create_user }

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to(have_http_status(:success))
    end
  end

  describe "POST #create" do
    context "com credenciais válidas" do
      it "faz login via session" do
        post :create, params: { email: user.email, password: "123456" }

        expect(response).to(redirect_to(root_path))
        expect(session[:user_id]).to(eq(user.id))
        expect(cookies.signed[:user_id]).to(be_nil)
      end

      it "persiste login via cookie quando 'Lembrar-me' é marcado" do
        post :create, params: { email: user.email, password: "123456", remember_me: "1" }

        expect(cookies.signed[:user_id]).to(eq(user.id))
      end

      it "define expiração no cookie 'Lembrar-me'" do
        post :create, params: { email: user.email, password: "123456", remember_me: "1" }

        expect(cookies[:user_id]).not_to(be_nil)
      end
    end

    context "com credenciais inválidas" do
      it "re-renderiza o formulário com alerta" do
        post :create, params: { email: user.email, password: "errada" }

        expect(response).to(have_http_status(:success))
        expect(flash[:alert]).to(eq("E-mail ou senha inválidos"))
        expect(session[:user_id]).to(be_nil)
      end
    end
  end

  describe "DELETE #destroy" do
    it "desloga e limpa a session" do
      session[:user_id] = user.id

      delete :destroy

      expect(response).to(redirect_to(root_path))
      expect(session[:user_id]).to(be_nil)
    end
  end
end
