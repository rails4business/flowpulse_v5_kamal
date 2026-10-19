class ConsolidateProductiveExperienceModel < ActiveRecord::Migration[8.1]
  def up
    add_reference :node_processes,
      :created_by_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_reference :node_processes,
      :responsible_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_reference :node_processes,
      :reference_data_experience,
      null: true,
      foreign_key: { to_table: :data_experiences }

    add_reference :data_experiences,
      :created_by_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_reference :data_experiences,
      :responsible_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_column :data_experiences, :status, :string, null: false, default: "draft"
    add_column :data_experiences, :started_at, :datetime
    add_column :data_experiences, :completed_at, :datetime

    add_reference :skill_products,
      :data_experience,
      null: true,
      foreign_key: true,
      index: { unique: true }

    add_reference :data_sessions,
      :created_by_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_column :data_sessions, :status, :string, null: false, default: "draft"
    change_column_null :data_sessions, :data_experience_id, true

    add_reference :data_slots,
      :created_by_profile,
      null: true,
      foreign_key: { to_table: :profiles }
    add_column :data_slots, :status, :string, null: false, default: "draft"

    backfill_creator_profiles
  end

  def down
    change_column_null :data_sessions, :data_experience_id, false

    remove_column :data_slots, :status
    remove_reference :data_slots, :created_by_profile, foreign_key: { to_table: :profiles }

    remove_column :data_sessions, :status
    remove_reference :data_sessions, :created_by_profile, foreign_key: { to_table: :profiles }

    remove_reference :skill_products, :data_experience, foreign_key: true

    remove_column :data_experiences, :completed_at
    remove_column :data_experiences, :started_at
    remove_column :data_experiences, :status
    remove_reference :data_experiences, :responsible_profile, foreign_key: { to_table: :profiles }
    remove_reference :data_experiences, :created_by_profile, foreign_key: { to_table: :profiles }

    remove_reference :node_processes, :reference_data_experience, foreign_key: { to_table: :data_experiences }
    remove_reference :node_processes, :responsible_profile, foreign_key: { to_table: :profiles }
    remove_reference :node_processes, :created_by_profile, foreign_key: { to_table: :profiles }
  end

  private

    def backfill_creator_profiles
      execute <<~SQL.squish
        UPDATE node_processes
        SET created_by_profile_id = profiles.id
        FROM profiles
        WHERE profiles.user_id = node_processes.created_by_user_id
          AND node_processes.created_by_profile_id IS NULL
      SQL

      execute <<~SQL.squish
        UPDATE data_experiences
        SET created_by_profile_id = profiles.id
        FROM profiles
        WHERE profiles.user_id = data_experiences.created_by_user_id
          AND data_experiences.created_by_profile_id IS NULL
      SQL

      execute <<~SQL.squish
        UPDATE data_sessions
        SET created_by_profile_id = data_experiences.created_by_profile_id
        FROM data_experiences
        WHERE data_experiences.id = data_sessions.data_experience_id
          AND data_sessions.created_by_profile_id IS NULL
      SQL

      execute <<~SQL.squish
        UPDATE data_slots
        SET created_by_profile_id = data_experiences.created_by_profile_id
        FROM data_experiences
        WHERE data_experiences.id = data_slots.data_experience_id
          AND data_slots.created_by_profile_id IS NULL
      SQL
    end
end
