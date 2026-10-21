# frozen_string_literal: true

require "rails_helper"

RSpec.describe(AdminController, type: :controller) do
  describe "GET #index" do
    context "como admin" do
      it "responde com sucesso" do
        admin = create_user(admin: true)
        session[:user_id] = admin.id

        get :index

        expect(response).to(have_http_status(:success))
      end

      it "expõe o total de usuários cadastrados" do
        admin = create_user(admin: true)
        create_user
        session[:user_id] = admin.id

        get :index

        expect(assigns(:metrics).users_count).to(eq(2))
      end

      it "expõe o total de contatos de todos os usuários" do
        admin = create_user(admin: true)
        outro = create_user
        create_contact(admin)
        create_contact(outro)
        create_contact(outro)
        session[:user_id] = admin.id

        get :index

        expect(assigns(:metrics).contacts_count).to(eq(3))
      end

      it "expõe uma série de 8 semanas, com a semana corrente preenchida" do
        admin = create_user(admin: true)
        create_contact(admin)
        session[:user_id] = admin.id

        get :index

        weeks = assigns(:metrics).weekly_contacts
        expect(weeks.length).to(eq(8))
        expect(weeks.last[:total]).to(eq(1))
      end

      it "carrega sem erro quando não há contatos (sem divisão por zero)" do
        admin = create_user(admin: true)
        session[:user_id] = admin.id

        get :index

        expect(response).to(have_http_status(:success))
        expect(assigns(:metrics).weekly_contacts.map { |w| w[:total] }).to(all(eq(0)))
      end
    end

    context "como usuário comum" do
      it "redireciona para a home com aviso" do
        session[:user_id] = create_user.id

        get :index

        expect(response).to(redirect_to(root_path))
      end

      it "não vaza nenhum número das métricas" do
        outro = create_user
        create_contact(outro)
        session[:user_id] = create_user.id

        get :index

        expect(response).to(redirect_to(root_path))
        expect(assigns(:metrics)).to(be_nil)
      end
    end

    context "sem autenticação" do
      it "redireciona para a home" do
        get :index

        expect(response).to(redirect_to(root_path))
      end

      it "não vaza nenhum número das métricas" do
        create_contact(create_user)

        get :index

        expect(response).to(redirect_to(root_path))
        expect(assigns(:metrics)).to(be_nil)
      end
    end
  end
end
