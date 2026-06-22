class CreateTravelerSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :traveler_subscriptions do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :subscribed_at, null: false

      t.timestamps
    end

    add_index :traveler_subscriptions, [:profile_id, :domain_id], unique: true
    add_index :traveler_subscriptions, [:profile_id, :node_id]
    add_index :traveler_subscriptions, :status
  end
end
