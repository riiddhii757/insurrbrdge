class AddPasswordRecoveryAndLoginLockoutToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :failed_login_attempts, :integer, null: false, default: 0
    add_column :users, :locked_at, :datetime
    add_column :users, :password_reset_digest, :string
    add_column :users, :password_reset_sent_at, :datetime
    add_index :users, :password_reset_digest, unique: true
  end
end
