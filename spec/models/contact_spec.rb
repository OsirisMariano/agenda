# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Contact, type: :model) do
  describe "associations" do
    it { is_expected.to(belong_to(:user)) }
  end

  describe "validations" do
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_most(50)) }
    it { is_expected.to(validate_presence_of(:phone)) }
  end

  describe "phone" do
    it "rejeita formato inválido" do
      contact = described_class.new(user: create_user, name: "Ana", phone: "123")
      expect(contact).not_to(be_valid)
    end

    it "aceita formato brasileiro válido" do
      contact = described_class.new(user: create_user, name: "Ana", phone: "(11) 98888-1234")
      expect(contact).to(be_valid)
    end

    it "é único por usuário" do
      user = create_user
      create_contact(user, phone: "(11) 98888-1234")

      duplicate = described_class.new(user: user, name: "Outro", phone: "(11) 98888-1234")
      expect(duplicate).not_to(be_valid)
    end

    it "permite o mesmo telefone entre usuários diferentes" do
      first = create_contact(create_user, phone: "(11) 98888-1234")
      second = described_class.new(user: create_user, name: "Outro", phone: "(11) 98888-1234")

      expect(first.user_id).not_to(eq(second.user_id))
      expect(second).to(be_valid)
    end
  end

  describe ".search" do
    it "busca por nome" do
      user = create_user
      create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")

      expect(described_class.search("Silva")).to(include(Contact.find_by(name: "Ana Silva")))
    end

    it "busca por telefone" do
      user = create_user
      create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")

      expect(described_class.search("98888")).to(include(Contact.find_by(name: "Ana Silva")))
    end
  end
end
