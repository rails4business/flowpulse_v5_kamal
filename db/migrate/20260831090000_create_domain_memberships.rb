class CreateDomainMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :domain_memberships do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :joined_at, null: false
      t.timestamps
    end

    add_index :domain_memberships, [:profile_id, :domain_id], unique: true
    add_index :domain_memberships, :status
  end
end
