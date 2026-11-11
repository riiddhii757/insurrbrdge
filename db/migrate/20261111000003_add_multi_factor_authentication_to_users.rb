class AddMultiFactorAuthenticationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :totp_secret, :text
    add_column :users, :totp_enabled_at, :datetime

    create_table :mfa_recovery_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :digest, null: false
      t.datetime :used_at
      t.timestamps
    end
    add_index :mfa_recovery_codes, :digest, unique: true
  end
end
