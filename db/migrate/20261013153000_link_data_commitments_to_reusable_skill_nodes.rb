class LinkDataCommitmentsToReusableSkillNodes < ActiveRecord::Migration[8.1]
  def change
    add_reference :data_commitments,
      :reusable_skill_node,
      null: true,
      foreign_key: true,
      index: true
  end
end
