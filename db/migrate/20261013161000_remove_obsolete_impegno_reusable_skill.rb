class RemoveObsoleteImpegnoReusableSkill < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      DELETE FROM reusable_skill_nodes
      WHERE reusable_skill_id IN (
        SELECT id FROM reusable_skills
        WHERE slug = '1impegno' AND resource_type = 'DataCommitment'
      )
      AND NOT EXISTS (
        SELECT 1 FROM skill_products
        WHERE skill_products.reusable_skill_node_id = reusable_skill_nodes.id
      )
    SQL

    execute <<~SQL.squish
      DELETE FROM reusable_skills
      WHERE slug = '1impegno'
      AND resource_type = 'DataCommitment'
      AND NOT EXISTS (
        SELECT 1 FROM reusable_skill_nodes
        WHERE reusable_skill_nodes.reusable_skill_id = reusable_skills.id
      )
    SQL
  end

  def down
    # Il catalogo delle Skill è la fonte per ricreare definizioni rimosse.
  end
end
