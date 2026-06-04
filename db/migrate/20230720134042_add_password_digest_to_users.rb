class AddPasswordDigestToUsers < ActiveRecord::Migration[7.0]
  def change
    #unless column_exists? :users, :password_digest
      add_column :users, :admin, :boolean, default: false, null: false
    end
  end
end
