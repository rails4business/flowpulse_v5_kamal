class CompleteReusableSkillContract < ActiveRecord::Migration[8.1]
  def change
    add_column :reusable_skills, :resource_type, :string
    add_column :reusable_skills, :documentation_markdown, :text

    add_column :reusable_skill_nodes, :status, :string, null: false, default: "draft"
    add_column :reusable_skill_nodes, :configuration, :jsonb, null: false, default: {}
    add_reference :reusable_skill_nodes,
      :activated_by_profile,
      null: true,
      foreign_key: { to_table: :profiles }

    create_table :reusable_skill_dependencies do |t|
      t.references :reusable_skill, null: false, foreign_key: true
      t.references :required_skill, null: false, foreign_key: { to_table: :reusable_skills }
      t.string :dependency_kind, null: false, default: "uses"
      t.timestamps
    end

    add_index :reusable_skill_dependencies,
      %i[reusable_skill_id required_skill_id],
      unique: true,
      name: "index_reusable_skill_dependencies_uniqueness"
  end
end
