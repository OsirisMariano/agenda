# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :contacts, dependent: :destroy

  attr_reader :reset_token

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
end
