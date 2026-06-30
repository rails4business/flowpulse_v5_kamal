class AddUsernameToProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :username, :string

    # Backfill existing profiles
    Profile.reset_column_information
    Profile.includes(:user).find_each do |profile|
      base_username = if profile.user&.email_address.present?
                        profile.user.email_address.split('@').first.downcase.gsub(/[^a-z0-9_]/, '_')
                      elsif profile.display_name.present?
                        profile.display_name.downcase.gsub(/[^a-z0-9_]/, '_')
                      else
                        "user_#{profile.id}"
                      end

      base_username = "user" if base_username.blank?

      username = base_username
      counter = 1
      while Profile.exists?(username: username)
        username = "#{base_username}_#{counter}"
        counter += 1
      end

      profile.update_column(:username, username)
    end

    # Make the column non-nullable
    change_column_null :profiles, :username, false

    # Add unique index
    add_index :profiles, :username, unique: true
  end

  def down
    remove_index :profiles, :username
    remove_column :profiles, :username
  end
end
