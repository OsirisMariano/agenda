# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Rack::Attack", type: :request) do
  include ActiveSupport::Testing::TimeHelpers

  describe "POST /entrar" do
    it "bloqueia após 5 tentativas em 1 minuto" do
      user = create_user

      5.times do
        post entrar_path, params: { email: user.email, password: "senha-errada" }
      end

      post entrar_path, params: { email: user.email, password: "senha-errada" }

      expect(response.status).to(eq(429))
      expect(response.body).to(include("Muitas tentativas de login"))
    end

    it "libera o acesso após a janela de 1 minuto" do
      user = create_user

      5.times do
        post entrar_path, params: { email: user.email, password: "senha-errada" }
      end

      post entrar_path, params: { email: user.email, password: "senha-errada" }
      expect(response.status).to(eq(429))

      travel 61.seconds do
        post entrar_path, params: { email: user.email, password: "123456" }
        expect(response).to(redirect_to(root_path))
      end
    end

    it "não bloqueia outras rotas" do
      6.times do
        get root_path
      end

      expect(response.status).not_to(eq(429))
    end
  end
end
