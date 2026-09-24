class RenameDataSessionServiceForeignKey < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :data_sessions, name: "fk_data_sessions_brand_activity", if_exists: true
    add_foreign_key :data_sessions, :services, name: "fk_data_sessions_service"
  end

  def down
    remove_foreign_key :data_sessions, name: "fk_data_sessions_service", if_exists: true
    add_foreign_key :data_sessions, :services, name: "fk_data_sessions_brand_activity"
  end
end
