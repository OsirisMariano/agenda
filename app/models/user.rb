# frozen_string_literal: true

class User < ApplicationRecord
  CONFIRMATION_EXPIRATION = 2.hours

  has_secure_password
  has_many :contacts, dependent: :destroy

  attr_reader :reset_token, :confirmation_token

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  def admin?
    admin
  end

  def create_reset_digest
    @reset_token = SecureRandom.urlsafe_base64
    update!(reset_digest: BCrypt::Password.create(@reset_token), reset_sent_at: Time.current)
  end

  def reset_authenticated?(token)
    reset_digest.present? && BCrypt::Password.new(reset_digest) == token
  end

  def reset_expired?
    reset_sent_at.nil? || reset_sent_at < 2.hours.ago
  end

  def confirmed?
    confirmed_at.present?
  end

  # O token em claro só existe em `@confirmation_token`, em memória, para ser
  # colocado no e-mail. No banco vai só o hash, como no reset de senha.
  def create_confirmation_digest
    @confirmation_token = SecureRandom.urlsafe_base64
    update!(
      confirmation_digest: BCrypt::Password.create(@confirmation_token),
      confirmation_sent_at: Time.current,
    )
  end

  def confirmation_authenticated?(token)
    confirmation_digest.present? && BCrypt::Password.new(confirmation_digest) == token
  end

  def confirmation_expired?
    confirmation_sent_at.nil? || confirmation_sent_at < CONFIRMATION_EXPIRATION.ago
  end

  # Limpa o digest no mesmo update: o link é de uso único, e um token que
  # sobrevive à confirmação permitiria reconfirmar a conta à mão.
  def confirm
    update!(confirmed_at: Time.current, confirmation_digest: nil)
  end
end
