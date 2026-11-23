class PrepareUnifiedContentAndLineNavigation < ActiveRecord::Migration[8.1]
  def up
    add_reference :nodes, :show_content, foreign_key: { to_table: :contents }, index: true
    add_reference :contents, :show_publication, foreign_key: { to_table: :content_publications }, index: true

    add_column :contents, :role, :string
    add_column :contents, :placement, :string
    add_column :contents, :editor, :string, default: "markdown", null: false
    add_column :contents, :sync_status, :string, default: "clean", null: false
    add_column :contents, :markdown_checksum, :string
    add_column :contents, :lexxy_checksum, :string
    add_column :contents, :markdown_updated_at, :datetime
    add_column :contents, :lexxy_updated_at, :datetime

    add_column :metro_lines, :station_node_slugs, :string, array: true, default: [], null: false

    execute <<~SQL.squish
      UPDATE contents
      SET role = CASE format
        WHEN 'course' THEN 'introduction'
        WHEN 'chapter' THEN 'chapter'
        ELSE 'material'
      END,
      placement = CASE format
        WHEN 'chapter' THEN 'after_chapters'
        ELSE 'after_body'
      END,
      markdown_updated_at = CASE WHEN body_md IS NOT NULL AND body_md <> '' THEN updated_at ELSE NULL END
    SQL

    change_column_null :contents, :role, false
    change_column_null :contents, :placement, false

    add_check_constraint :contents,
      "role IN ('introduction', 'chapter', 'material', 'attachment')",
      name: "contents_role_allowed"
    add_check_constraint :contents,
      "placement IN ('before_body', 'after_body', 'after_chapters')",
      name: "contents_placement_allowed"
    add_check_constraint :contents,
      "editor IN ('markdown', 'lexxy')",
      name: "contents_editor_allowed"
    add_check_constraint :contents,
      "sync_status IN ('clean', 'markdown_changed', 'lexxy_changed', 'conflict')",
      name: "contents_sync_status_allowed"
  end

  def down
    remove_check_constraint :contents, name: "contents_sync_status_allowed"
    remove_check_constraint :contents, name: "contents_editor_allowed"
    remove_check_constraint :contents, name: "contents_placement_allowed"
    remove_check_constraint :contents, name: "contents_role_allowed"

    remove_column :metro_lines, :station_node_slugs
    remove_column :contents, :lexxy_updated_at
    remove_column :contents, :markdown_updated_at
    remove_column :contents, :lexxy_checksum
    remove_column :contents, :markdown_checksum
    remove_column :contents, :sync_status
    remove_column :contents, :editor
    remove_column :contents, :placement
    remove_column :contents, :role
    remove_reference :contents, :show_publication, foreign_key: { to_table: :content_publications }
    remove_reference :nodes, :show_content, foreign_key: { to_table: :contents }
  end
end
