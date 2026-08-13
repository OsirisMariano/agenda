# frozen_string_literal: true

module FactoryHelpers
  def create_user(overrides = {})
    User.create!(
      {
        name: "Usuário Teste",
        email: "teste_#{SecureRandom.hex(4)}@exemplo.com",
        password: "123456",
        password_confirmation: "123456",
      }.merge(overrides),
    )
  end

  def create_contact(user, overrides = {})
    Contact.create!(
      {
        name: "Contato Teste",
        phone: "(11) 9#{rand(1000..9999)}-#{rand(1000..9999)}",
      }.merge(overrides).merge(user: user),
    )
  end
end

RSpec.configure do |config|
  config.include(FactoryHelpers)
end
