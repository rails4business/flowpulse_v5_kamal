class AddPlanningDatesToExperienceTree < ActiveRecord::Migration[8.1]
  def change
    add_column :data_sessions, :starts_at, :datetime
    add_column :data_sessions, :ends_at, :datetime
    add_index :data_sessions, %i[data_experience_id starts_at]
  end
end
