# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Confirmação de e-mail (US09)", type: :request) do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create_user(confirmed_at: nil, email: "pendente@exemplo.com") }

  def confirmar(u = user, token = nil)
    token ||= u.instance_variable_get(:@confirmation_token)
    get(confirmar_email_path(email: u.email, token: token))
  end

  describe "GET /confirmar-email" do
    it "confirma a conta e manda para o login" do
      user.create_confirmation_digest

      confirmar

      expect(user.reload).to(be_confirmed)
      expect(response).to(redirect_to(entrar_url))
      follow_redirect!
      expect(response.body).to(include("E-mail confirmado com sucesso!"))
    end

    it "funciona sem sessão, porque o link vem por e-mail" do
      user.create_confirmation_digest

      confirmar

      expect(session[:user_id]).to(be_nil)
    end

    it "recusa token expirado e mantém a conta pendente" do
      user.create_confirmation_digest
      user.update!(confirmation_sent_at: 3.hours.ago)

      confirmar

      expect(user.reload).not_to(be_confirmed)
      expect(response).to(redirect_to(entrar_url))
      follow_redirect!
      expect(response.body).to(include("Link de confirmação inválido, expirado ou já utilizado."))
    end

    it "recusa token inválido" do
      user.create_confirmation_digest

      get confirmar_email_path(email: user.email, token: "token-errado")

      expect(user.reload).not_to(be_confirmed)
      follow_redirect!
      expect(response.body).to(include("Link de confirmação inválido, expirado ou já utilizado."))
    end

    it "recusa e-mail inexistente" do
      user.create_confirmation_digest

      get confirmar_email_path(email: "ninguem@exemplo.com", token: user.confirmation_token)

      expect(user.reload).not_to(be_confirmed)
      follow_redirect!
      expect(response.body).to(include("Link de confirmação inválido, expirado ou já utilizado."))
    end

    it "recusa o mesmo link uma segunda vez" do
      user.create_confirmation_digest
      token = user.confirmation_token
      confirmar(user, token)

      get confirmar_email_path(email: user.email, token: token)

      follow_redirect!
      expect(response.body).to(include("Link de confirmação inválido, expirado ou já utilizado."))
    end

    it "recusa link de conta já confirmada" do
      confirmed = create_user(email: "ja-confirmado@exemplo.com")
      confirmed.create_confirmation_digest
      token = confirmed.confirmation_token

      confirmar(confirmed, token)

      expect(response).to(redirect_to(entrar_url))
      follow_redirect!
      expect(response.body).to(include("Link de confirmação inválido, expirado ou já utilizado."))
    end
  end

  describe "POST /reenviar-confirmacao" do
    it "gera um token novo e reenvia o e-mail" do
      post reenviar_confirmacao_path, params: { email: user.email }
      expect(ActionMailer::Base.deliveries.last.to).to(eq([user.email]))
      antigo = user.reload.confirmation_digest

      post reenviar_confirmacao_path, params: { email: user.email }

      expect(ActionMailer::Base.deliveries.last.to).to(eq([user.email]))
      expect(user.reload.confirmation_digest).not_to(eq(antigo))
    end

    it "responde a mesma coisa para e-mail que não existe" do
      post reenviar_confirmacao_path, params: { email: "ninguem@exemplo.com" }

      expect(ActionMailer::Base.deliveries).to(be_empty)
      expect(response).to(redirect_to(entrar_url))
      follow_redirect!
      expect(response.body).to(include("Se este e-mail existir e não estiver confirmado"))
    end

    it "não reenvia para conta já confirmada" do
      confirmado = create_user

      post reenviar_confirmacao_path, params: { email: confirmado.email }

      expect(ActionMailer::Base.deliveries).to(be_empty)
    end

    it "não deixa a conta confirmada" do
      post reenviar_confirmacao_path, params: { email: user.email }

      expect(user.reload).not_to(be_confirmed)
    end
  end

  describe "gate de confirmação no login" do
    it "não cria sessão para conta não confirmada" do
      post entrar_path, params: { email: user.email, password: "123456" }

      expect(session[:user_id]).to(be_nil)
      expect(response).to(redirect_to(reenviar_confirmacao_url))
    end

    it "não deixa o cookie de lembrar-me ser gravado" do
      post entrar_path, params: { email: user.email, password: "123456", remember_me: "1" }

      expect(session[:user_id]).to(be_nil)
      expect(cookies[:user_id]).to(be_nil)
    end

    it "avisa que falta confirmar" do
      post entrar_path, params: { email: user.email, password: "123456" }

      follow_redirect!
      expect(response.body).to(include("Confirme seu e-mail antes de entrar."))
    end

    it "cria sessão depois que a conta é confirmada" do
      user.create_confirmation_digest
      confirmar
      post entrar_path, params: { email: user.email, password: "123456" }

      expect(session[:user_id]).to(eq(user.id))
      expect(response).to(redirect_to(root_url))
    end

    it "continua recusando senha errada de conta confirmada" do
      post entrar_path, params: { email: user.email, password: "errada" }

      expect(session[:user_id]).to(be_nil)
    end
  end

  describe "GET /reenviar-confirmacao" do
    it "mostra o formulário sem sessão" do
      get reenviar_confirmacao_path

      expect(response).to(have_http_status(:ok))
      expect(response.body).to(include("Reenviar confirmação"))
    end
  end
end
