class CreateCoreInsuranceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :agencies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "trial"
      t.string :timezone, null: false, default: "America/New_York"
      t.timestamps
    end
    add_index :agencies, :slug, unique: true

    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.boolean :platform_admin, null: false, default: false
      t.datetime :disabled_at
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    create_table :memberships do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "producer"
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :memberships, [:agency_id, :user_id], unique: true

    create_table :customers do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :legal_name, null: false
      t.string :dba_name
      t.string :entity_type
      t.string :industry
      t.string :website
      t.string :email
      t.string :phone
      t.string :status, null: false, default: "prospect"
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :customers, [:agency_id, :legal_name]

    create_table :insurance_submissions do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :reference, null: false
      t.string :line_of_business, null: false, default: "general_liability"
      t.string :status, null: false, default: "draft"
      t.date :effective_date
      t.date :expiration_date
      t.string :state
      t.jsonb :business_details, null: false, default: {}
      t.jsonb :exposures, null: false, default: {}
      t.jsonb :requested_coverages, null: false, default: {}
      t.text :underwriter_notes
      t.timestamps
    end
    add_index :insurance_submissions, :reference, unique: true
    add_index :insurance_submissions, [:agency_id, :status]

    create_table :carriers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :integration_status, null: false, default: "planned"
      t.string :environment, null: false, default: "sandbox"
      t.jsonb :supported_lines, null: false, default: []
      t.jsonb :supported_states, null: false, default: []
      t.text :integration_notes
      t.timestamps
    end
    add_index :carriers, :slug, unique: true

    create_table :market_submissions do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :insurance_submission, null: false, foreign_key: true
      t.references :carrier, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.string :carrier_reference
      t.string :environment, null: false, default: "demo"
      t.string :correlation_id
      t.datetime :submitted_at
      t.datetime :responded_at
      t.jsonb :appetite_result, null: false, default: {}
      t.jsonb :response_metadata, null: false, default: {}
      t.text :failure_reason
      t.timestamps
    end
    add_index :market_submissions, [:insurance_submission_id, :carrier_id], unique: true
    add_index :market_submissions, [:agency_id, :status]

    create_table :quotes do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :market_submission, null: false, foreign_key: true
      t.string :carrier_quote_reference
      t.string :status, null: false, default: "received"
      t.string :source, null: false, default: "carrier"
      t.string :environment, null: false, default: "sandbox"
      t.string :currency, null: false, default: "USD"
      t.decimal :premium, precision: 12, scale: 2
      t.decimal :fees, precision: 12, scale: 2
      t.decimal :taxes, precision: 12, scale: 2
      t.date :effective_date
      t.date :expires_at
      t.jsonb :coverages, null: false, default: {}
      t.jsonb :conditions, null: false, default: []
      t.jsonb :exclusions, null: false, default: []
      t.jsonb :source_metadata, null: false, default: {}
      t.timestamps
    end
    add_index :quotes, :carrier_quote_reference

    create_table :audit_events do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :record_type, null: false
      t.bigint :record_id
      t.string :request_id
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :audit_events, [:agency_id, :created_at]
    add_index :audit_events, [:record_type, :record_id]
  end
end
