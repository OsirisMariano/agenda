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
end
