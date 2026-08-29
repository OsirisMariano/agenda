# frozen_string_literal: true

require "rails_helper"

RSpec.describe(User, type: :model) do
  describe "associations" do
    it { is_expected.to(have_many(:contacts).dependent(:destroy)) }
  end

  describe "validations" do
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_most(100)) }
    it { is_expected.to(validate_presence_of(:email)) }
    it { is_expected.to(validate_uniqueness_of(:email).case_insensitive) }
    it { is_expected.to(validate_length_of(:password).is_at_least(6)) }
  end

  describe "email" do
    it "rejeita e-mail sem formato válido" do
      user = described_class.new(name: "Teste", email: "invalido", password: "123456")
      expect(user).not_to(be_valid)
    end

    it "aceita e-mail válido" do
      user = described_class.new(
        name: "Teste",
        email: "teste@exemplo.com",
        password: "123456",
        password_confirmation: "123456",
      )
      expect(user).to(be_valid)
    end
  end

  describe "senha" do
    it "exige confirmação quando senha está presente" do
      user = described_class.new(
        name: "Teste",
        email: "teste@exemplo.com",
        password: "123456",
        password_confirmation: "outra",
      )
      expect(user).not_to(be_valid)
    end
  end

  describe "#admin?" do
    it "retorna false por padrão" do
      expect(described_class.new.admin?).to(be(false))
    end

    it "retorna true quando a coluna admin é verdadeira" do
      expect(described_class.new(admin: true).admin?).to(be(true))
    end
  end

  describe "recuperação de senha" do
    let(:user) { create_user }

    describe "#create_reset_digest" do
      it "define o digest, o horário e o token na memória" do
        user.create_reset_digest

        expect(user.reset_digest).to(be_present)
        expect(user.reset_sent_at).to(be_present)
        expect(user.reset_token).to(be_present)
      end

      it "não armazena o token cru no banco" do
        user.create_reset_digest

        expect(user.reload.reset_digest).not_to(eq(user.reset_token))
        expect(BCrypt::Password.new(user.reset_digest) == user.reset_token).to(be(true))
      end
    end

    describe "#reset_authenticated?" do
      before { user.create_reset_digest }

      it "retorna true quando o token é o correto" do
        expect(user.reset_authenticated?(user.reset_token)).to(be(true))
      end

      it "retorna false quando o token é inválido" do
        expect(user.reset_authenticated?("token-invalido")).to(be(false))
      end

      it "retorna false quando não há digest" do
        expect(described_class.new.reset_authenticated?("qualquer")).to(be(false))
      end
    end

    describe "#reset_expired?" do
      it "retorna false logo após criar o digest" do
        user.create_reset_digest

        expect(user.reset_expired?).to(be(false))
      end

      it "retorna true quando nunca houve digest" do
        expect(described_class.new.reset_expired?).to(be(true))
      end

      it "retorna true após 2 horas" do
        user.create_reset_digest
        user.update!(reset_sent_at: 3.hours.ago)

        expect(user.reset_expired?).to(be(true))
      end
    end
  end
end
