class AddAuthSessionVersionToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :auth_session_version, :integer, null: false, default: 0
  end
end
