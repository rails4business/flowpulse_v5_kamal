class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name
      t.string :first_name
      t.string :last_name
      t.string :role

      t.timestamps
    end
  end
end
