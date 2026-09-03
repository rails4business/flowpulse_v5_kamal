class CreateDataEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :data_events do |t|
      t.references :parent, foreign_key: { to_table: :data_events }
      t.references :domain, null: false, foreign_key: true
      t.references :created_by_profile, null: false, foreign_key: { to_table: :profiles }
      t.references :responsible_profile, foreign_key: { to_table: :profiles }
      t.references :place, foreign_key: { to_table: :impegno_places }
      t.references :service_data_event, foreign_key: { to_table: :data_events }

      t.string :title, null: false
      t.text :description
      t.string :classification, null: false
      t.string :node_kind, null: false, default: "root"
      t.integer :position, null: false, default: 0

      t.date :active_from
      t.date :active_until
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :all_day, null: false, default: false
      t.jsonb :recurrence, null: false, default: {}

      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "private"
      t.datetime :published_at
      t.string :registration_status, null: false, default: "pending"
      t.string :registration_mode, null: false, default: "none"

      t.boolean :bookable, null: false, default: false
      t.string :booking_mode, null: false, default: "none"
      t.text :booking_notes
      t.boolean :service_definition, null: false, default: false
      t.string :service_scope, null: false, default: "private"
      t.datetime :archived_at
      t.integer :price_cents
      t.string :currency, null: false, default: "EUR"
      t.integer :duration_minutes
      t.integer :minimum_participants
      t.integer :maximum_participants
      t.jsonb :allowed_roles, null: false, default: []
      t.jsonb :operator_roles, null: false, default: []
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :data_events, %i[parent_id position]
    add_index :data_events, %i[domain_id classification status]
    add_index :data_events, %i[starts_at ends_at]
    add_index :data_events, :published_at
    add_index :data_events, :recurrence, using: :gin

    change_table :data_commitments, bulk: true do |t|
      t.references :parent, foreign_key: { to_table: :data_commitments }
      t.references :requested_data_event, foreign_key: { to_table: :data_events }
      t.references :data_event, foreign_key: true
      t.string :participation_role
      t.integer :agreed_price_cents
      t.string :agreed_currency
      t.integer :agreed_duration_minutes
      t.jsonb :agreement_snapshot, null: false, default: {}
    end

    add_reference :impegno_places, :domain, foreign_key: true
    add_column :impegno_places, :scope, :string, null: false, default: "private"
    add_column :impegno_places, :approval_status, :string, null: false, default: "draft"
    add_index :impegno_places, %i[domain_id scope approval_status], name: "index_impegno_places_on_domain_scope_approval"
  end
end
