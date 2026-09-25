class DataExperience < ApplicationRecord
  belongs_to :created_by_user, class_name: "User"
  belongs_to :brand_process, optional: true
  has_many :data_sessions, dependent: :restrict_with_error
  has_many :data_slots, dependent: :restrict_with_error
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :restrict_with_error

  validates :title, presence: true
end
