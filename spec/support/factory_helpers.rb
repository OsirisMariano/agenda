# frozen_string_literal: true

module FactoryHelpers
  # Confirmado por padrão (US09): o login passa a exigir confirmação, e um
  # helper que devolvesse usuário pendente quebraria todas as specs que
  # autenticam de uma vez. O caminho não-confirmado se exercita com
  # `create_user(confirmed_at: nil)`.
  def create_user(overrides = {})
    User.create!(
      {
        name: "Usuário Teste",
        email: "teste_#{SecureRandom.hex(4)}@exemplo.com",
        password: "123456",
        password_confirmation: "123456",
        confirmed_at: Time.current,
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
