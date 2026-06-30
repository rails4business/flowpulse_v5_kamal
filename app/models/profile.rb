class Profile < ApplicationRecord
  belongs_to :user
  has_many :role_assignments, dependent: :destroy
  has_many :traveler_subscriptions, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "può contenere solo lettere, numeri e underscore (_)" },
                       length: { minimum: 3, maximum: 30 }

  before_validation :set_default_username, on: :create
  before_validation :normalize_username

  private

    def set_default_username
      return if username.present?

      base = if user&.email_address.present?
               user.email_address.split('@').first.downcase.gsub(/[^a-z0-9_]/, '_')[0...30]
             elsif display_name.present?
               display_name.downcase.gsub(/[^a-z0-9_]/, '_')[0...30]
             else
               "user"
             end

      base = "user" if base.blank?

      username_val = base
      counter = 1
      while Profile.exists?(username: username_val)
        username_val = "#{base}_#{counter}"[0...30]
        counter += 1
      end
      self.username = username_val
    end

    def normalize_username
      self.username = username.to_s.strip.downcase if username.present?
    end
end
