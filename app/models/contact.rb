# frozen_string_literal: true

class Contact < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true

  belongs_to :user

  scope :search, ->(query) { 
    where("name LIKE :q OR phone LIKE :q", q: "%#{query}%") 
  }
end
