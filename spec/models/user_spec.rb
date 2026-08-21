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
end
