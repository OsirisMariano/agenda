# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Sessions", type: :request) do
  let(:user) { create_user }

  describe "POST /entrar" do
    context "com 'Lembrar-me' marcado" do
      it "persiste o login via cookie" do
        post entrar_path, params: { email: user.email, password: "123456", remember_me: "1" }

        expect(cookies[:user_id]).to(be_present)
      end
    end

    context "sem 'Lembrar-me'" do
      it "não define cookie" do
        post entrar_path, params: { email: user.email, password: "123456" }

        expect(cookies[:user_id]).to(be_nil)
      end
    end
  end

  describe "DELETE /sair" do
    it "limpa session e cookie 'Lembrar-me'" do
      post entrar_path, params: { email: user.email, password: "123456", remember_me: "1" }
      expect(cookies[:user_id]).to(be_present)

      delete sair_path

      expect(response).to(redirect_to(root_path))
      expect(cookies[:user_id]).to(be_blank)
    end
  end
end
