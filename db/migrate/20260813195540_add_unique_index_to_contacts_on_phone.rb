# frozen_string_literal: true

class AddUniqueIndexToContactsOnPhone < ActiveRecord::Migration[7.0]
  def change
    add_index(:contacts, [:user_id, :phone], unique: true)
  end
end
