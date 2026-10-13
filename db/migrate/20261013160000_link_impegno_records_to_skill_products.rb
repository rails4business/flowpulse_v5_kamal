class LinkImpegnoRecordsToSkillProducts < ActiveRecord::Migration[8.1]
  def change
    remove_reference :data_commitments,
      :reusable_skill_node,
      foreign_key: true,
      index: true

    add_reference :data_commitments, :skill_product, null: true, foreign_key: true, index: true
    add_reference :data_sessions, :skill_product, null: true, foreign_key: true, index: true
    add_reference :data_slots, :skill_product, null: true, foreign_key: true, index: true
  end
end
