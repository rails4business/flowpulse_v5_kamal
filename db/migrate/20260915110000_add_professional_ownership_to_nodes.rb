class AddProfessionalOwnershipToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :professional, :boolean, null: false, default: false
    add_reference :nodes,
      :professional_owner_node,
      null: true,
      foreign_key: { to_table: :nodes },
      index: true

    add_reference :profiles,
      :primary_node,
      null: true,
      foreign_key: { to_table: :nodes },
      index: { unique: true }
  end
end
