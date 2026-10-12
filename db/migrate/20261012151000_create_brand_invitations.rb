class CreateBrandInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_invitations do |t|
      t.references :brand_node, null: false, foreign_key: { to_table: :nodes }
      t.references :source_domain, foreign_key: { to_table: :domains }
      t.references :invited_by_user, null: false, foreign_key: { to_table: :users }
      t.references :accepted_by_user, foreign_key: { to_table: :users }
      t.string :email_address, null: false
      t.string :token_digest, null: false
      t.string :status, null: false, default: "pending"
      t.string :role_code
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps
    end

    add_index :brand_invitations, :token_digest, unique: true
    add_index :brand_invitations, %i[brand_node_id email_address status], name: "index_brand_invitations_lookup"
  end
end
