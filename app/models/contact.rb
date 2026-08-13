# frozen_string_literal: true

class Contact < ApplicationRecord
  PHONE_REGEX = /\A(\+\d{1,3}[-\s.]?)?\(?\d{2}\)?[-\s.]?\d{4,5}[-\s.]?\d{4}\z/

  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone,
    presence: true,
    format: { with: PHONE_REGEX, message: "inválido. Use o formato (XX) XXXXX-XXXX." },
    uniqueness: { scope: :user_id }

  scope :search, ->(query) {
    where("name ILIKE :q OR phone ILIKE :q", q: "%#{query}%")
  }
end
