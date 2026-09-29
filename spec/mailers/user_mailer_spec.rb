# frozen_string_literal: true

require "rails_helper"

RSpec.describe("UserMailer", type: :mailer) do
  describe "#password_reset" do
    let(:user) { create_user }
    let(:mail) { UserMailer.password_reset(user) }

    before { user.create_reset_digest }

    it "usa o assunto em português" do
      expect(mail.subject).to(eq("Recuperação de senha"))
    end

    it "envia para o e-mail do usuário" do
      expect(mail.to).to(eq([user.email]))
    end

    it "usa o remetente padrão da aplicação" do
      expect(mail.from).to(eq(["from@example.com"]))
    end

    it "inclui o nome do usuário no corpo" do
      expect(mail.text_part.body.decoded).to(include(user.name))
      expect(mail.html_part.body.decoded).to(include(user.name))
    end

    it "inclui o link para definir a nova senha com o token" do
      link = "recuperar-senha/edit?email=#{CGI.escape(user.email)}&token=#{user.reset_token}"
      expect(mail.text_part.body.decoded).to(include(link))
      expect(mail.html_part.body.decoded).to(include("recuperar-senha/edit"))
      expect(mail.html_part.body.decoded).to(include("token=#{user.reset_token}"))
    end
  end

  describe "#confirmation" do
    let(:user) { create_user(confirmed_at: nil) }
    let(:mail) { UserMailer.confirmation(user) }

    before { user.create_confirmation_digest }

    it "usa o assunto em português" do
      expect(mail.subject).to(eq("Confirme seu e-mail"))
    end

    it "envia para o e-mail do usuário" do
      expect(mail.to).to(eq([user.email]))
    end

    it "usa o remetente padrão da aplicação" do
      expect(mail.from).to(eq(["from@example.com"]))
    end

    it "inclui o nome do usuário no corpo" do
      expect(mail.text_part.body.decoded).to(include(user.name))
      expect(mail.html_part.body.decoded).to(include(user.name))
    end

    it "inclui o link de confirmação com o token" do
      link = "confirmar-email?email=#{CGI.escape(user.email)}&token=#{user.confirmation_token}"
      expect(mail.text_part.body.decoded).to(include(link))
      expect(mail.html_part.body.decoded).to(include("confirmar-email"))
      expect(mail.html_part.body.decoded).to(include("token=#{user.confirmation_token}"))
    end

    it "avisa que a conta não confirmada não acessa o sistema" do
      expect(mail.text_part.body.decoded).to(include("2 horas"))
      expect(mail.text_part.body.decoded).to(include("ignore este e-mail"))
    end
  end
end
