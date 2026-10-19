class NodeProcess < ApplicationRecord
  STATUSES = %w[draft active archived].freeze

  belongs_to :node
  belongs_to :created_by_user, class_name: "User"
  belongs_to :created_by_profile, class_name: "Profile", optional: true
  belongs_to :responsible_profile, class_name: "Profile", optional: true
  belongs_to :reference_data_experience, class_name: "DataExperience", optional: true
  has_many :data_experiences, dependent: :nullify, inverse_of: :node_process

  before_validation :set_slug, if: -> { slug.blank? && title.present? }
  before_validation :set_created_by_profile, if: -> { created_by_profile.blank? && created_by_user.present? }

  validates :title, :slug, presence: true
  validates :slug, uniqueness: { scope: :node_id }, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }
  validate :reference_experience_belongs_to_process

  private

    def set_slug
      self.slug = title.parameterize
    end

    def set_created_by_profile
      self.created_by_profile = created_by_user.profile
    end

    def reference_experience_belongs_to_process
      return if reference_data_experience.blank?
      return if reference_data_experience.node_process == self

      errors.add(:reference_data_experience, "deve appartenere a questo processo")
    end
end
