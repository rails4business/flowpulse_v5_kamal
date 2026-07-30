class CreateDataCommitments < ActiveRecord::Migration[8.1]
  def change
    create_table :data_commitments do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :created_by_profile, null: false, foreign_key: { to_table: :profiles }
      t.references :domain, null: false, foreign_key: true
      t.references :subject, polymorphic: true, null: true

      t.string :title, null: false
      t.text :description
      t.string :kind, null: false, default: "work"
      t.string :status, null: false, default: "completed"
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.boolean :all_day, null: false, default: false

      t.string :location_name
      t.string :location_address
      t.string :online_url

      t.string :pricing_type, null: false, default: "hourly"
      t.decimal :hourly_rate, precision: 10, scale: 2
      t.decimal :total_price, precision: 12, scale: 2
      t.string :contribution_type, null: false, default: "time_investment"

      t.jsonb :genera_impresa, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :data_commitments, :starts_at
    add_index :data_commitments, :status
    add_index :data_commitments, :kind
    add_index :data_commitments, :genera_impresa, using: :gin
  end
end
