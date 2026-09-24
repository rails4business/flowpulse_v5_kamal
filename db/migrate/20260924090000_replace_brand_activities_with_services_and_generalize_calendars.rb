class ReplaceBrandActivitiesWithServicesAndGeneralizeCalendars < ActiveRecord::Migration[8.1]
  def change
    rename_table :brand_activities, :services
    rename_column :data_sessions, :brand_activity_id, :service_id
    rename_column :professional_calendars, :brand_node_id, :context_node_id
  end
end
