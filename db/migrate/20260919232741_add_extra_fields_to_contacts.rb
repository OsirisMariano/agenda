# frozen_string_literal: true

class AddExtraFieldsToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column(:contacts, :email, :string)
    add_column(:contacts, :address, :string)
    add_column(:contacts, :notes, :text)
  end
end
