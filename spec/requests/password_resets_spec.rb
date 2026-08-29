# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Recuperação de senha", type: :request) do
  describe "POST /recuperar-senha" do
    context "quando o e-mail existe" do
      it "gera o digest, envia o e-mail e redireciona com mensagem genérica" do
        user = create_user

        expect do
          post(recuperar_senha_path, params: { email: user.email })
        end.to(change { ActionMailer::Base.deliveries.count }.by(1))

        expect(user.reload.reset_digest).to(be_present)
        expect(user.reload.reset_sent_at).to(be_present)
        expect(response).to(redirect_to(root_path))
        expect(flash[:notice]).to(include("enviaremos um link de recuperação"))
      end
    end

    context "quando o e-mail não existe" do
      it "não envia e-mail e mantém a resposta genérica" do
        expect do
          post(recuperar_senha_path, params: { email: "nao-existe@exemplo.com" })
        end.not_to(change { ActionMailer::Base.deliveries.count })

        expect(response).to(redirect_to(root_path))
        expect(flash[:notice]).to(include("enviaremos um link de recuperação"))
      end
    end
  end

  describe "PATCH /recuperar-senha" do
    let(:user) { create_user }

    before { user.create_reset_digest }

    context "com token e e-mail válidos" do
      it "atualiza a senha e redireciona para o login" do
        patch recuperar_senha_path, params: {
          token: user.reset_token,
          email: user.email,
          user: { password: "nova-senha", password_confirmation: "nova-senha" },
        }

        expect(response).to(redirect_to(entrar_path))
        expect(flash[:notice]).to(eq("Senha redefinida com sucesso!"))
        expect(user.reload.authenticate("nova-senha")).to(be_truthy)
        expect(user.reload.authenticate("123456")).to(be_falsey)
      end

      it "rejeita quando a confirmação diverge" do
        patch recuperar_senha_path, params: {
          token: user.reset_token,
          email: user.email,
          user: { password: "nova-senha", password_confirmation: "outra" },
        }

        expect(response).to(have_http_status(:unprocessable_entity))
        expect(user.reload.authenticate("123456")).to(be_truthy)
      end

      it "rejeita senha em branco" do
        patch recuperar_senha_path, params: {
          token: user.reset_token,
          email: user.email,
          user: { password: "", password_confirmation: "" },
        }

        expect(response).to(have_http_status(:unprocessable_entity))
        expect(user.reload.authenticate("123456")).to(be_truthy)
      end
    end

    context "com token inválido" do
      it "redireciona para o formulário de e-mail" do
        patch recuperar_senha_path, params: {
          token: "invalido",
          email: user.email,
          user: { password: "nova-senha", password_confirmation: "nova-senha" },
        }

        expect(response).to(redirect_to(recuperar_senha_path))
        expect(flash[:alert]).to(eq("Link de recuperação inválido ou expirado."))
      end
    end

    context "com token expirado" do
      it "redireciona para o formulário de e-mail" do
        user.update!(reset_sent_at: 3.hours.ago)

        patch recuperar_senha_path, params: {
          token: user.reset_token,
          email: user.email,
          user: { password: "nova-senha", password_confirmation: "nova-senha" },
        }

        expect(response).to(redirect_to(recuperar_senha_path))
        expect(flash[:alert]).to(eq("Link de recuperação inválido ou expirado."))
      end
    end

    context "com e-mail inexistente" do
      it "redireciona para o formulário de e-mail" do
        patch recuperar_senha_path, params: {
          token: user.reset_token,
          email: "nao-existe@exemplo.com",
          user: { password: "nova-senha", password_confirmation: "nova-senha" },
        }

        expect(response).to(redirect_to(recuperar_senha_path))
        expect(flash[:alert]).to(eq("Link de recuperação inválido ou expirado."))
      end
    end
  end
end
