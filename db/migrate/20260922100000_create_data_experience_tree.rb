class CreateDataExperienceTree < ActiveRecord::Migration[8.1]
  def change
    create_table :data_experiences do |t|
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.timestamps
    end

    create_table :data_sessions do |t|
      t.references :data_experience, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :data_slots do |t|
      t.references :data_session, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :data_sessions, %i[data_experience_id position]
    add_index :data_slots, %i[data_session_id position]
  end
end
