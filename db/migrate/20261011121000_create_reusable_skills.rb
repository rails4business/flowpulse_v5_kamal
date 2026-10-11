class CreateReusableSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :reusable_skills do |t|
      t.references :owner_profile, null: false, foreign_key: { to_table: :profiles }
      t.references :responsible_profile, null: true, foreign_key: { to_table: :profiles }
      t.string :title, null: false
      t.string :slug, null: false
      t.string :category, null: false, default: "other"
      t.string :status, null: false, default: "idea"
      t.text :description
      t.text :purpose
      t.text :operation_notes
      t.text :reuse_notes
      t.timestamps
    end

    add_index :reusable_skills, %i[owner_profile_id slug], unique: true
    add_index :reusable_skills, %i[owner_profile_id status]

    create_table :reusable_skill_nodes do |t|
      t.references :reusable_skill, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true
      t.timestamps
    end
    add_index :reusable_skill_nodes, %i[reusable_skill_id node_id], unique: true, name: "index_reusable_skill_nodes_uniqueness"

    create_table :problem_solving_cycle_skills do |t|
      t.references :problem_solving_cycle, null: false, foreign_key: true
      t.references :reusable_skill, null: false, foreign_key: true
      t.timestamps
    end
    add_index :problem_solving_cycle_skills,
      %i[problem_solving_cycle_id reusable_skill_id],
      unique: true,
      name: "index_problem_cycles_skills_uniqueness"
  end
end
