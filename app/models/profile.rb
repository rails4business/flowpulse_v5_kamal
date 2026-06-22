class Profile < ApplicationRecord
  belongs_to :user
  has_many :role_assignments, dependent: :destroy
  has_many :traveler_subscriptions, dependent: :destroy

  validates :user_id, uniqueness: true
end
