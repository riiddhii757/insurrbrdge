class AddEmailVerificationToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :email_verified_at, :datetime
    add_column :users, :email_verification_digest, :string
    add_column :users, :email_verification_sent_at, :datetime
    add_index :users, :email_verification_digest, unique: true
    # Preserve access for accounts that existed before verification was introduced.
    execute "UPDATE users SET email_verified_at = CURRENT_TIMESTAMP WHERE email_verified_at IS NULL"
  end

  def down
    remove_index :users, :email_verification_digest
    remove_column :users, :email_verification_sent_at
    remove_column :users, :email_verification_digest
    remove_column :users, :email_verified_at
  end
end
