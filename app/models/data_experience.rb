class DataExperience < ApplicationRecord
  STATUSES = %w[draft planned in_progress completed cancelled archived].freeze

  belongs_to :created_by_user, class_name: "User"
  belongs_to :created_by_profile, class_name: "Profile", optional: true
  belongs_to :responsible_profile, class_name: "Profile", optional: true
  belongs_to :node_process, optional: true, inverse_of: :data_experiences
  has_one :skill_product, dependent: :restrict_with_error, inverse_of: :data_experience
  has_many :referencing_node_processes,
           class_name: "NodeProcess",
           foreign_key: :reference_data_experience_id,
           dependent: :nullify,
           inverse_of: :reference_data_experience
  has_many :data_sessions, dependent: :restrict_with_error, inverse_of: :data_experience
  has_many :data_slots, dependent: :restrict_with_error, inverse_of: :data_experience
  has_many :data_commitments,
           class_name: "Brands::Impegno::Commitment",
           dependent: :restrict_with_error,
           inverse_of: :data_experience

  before_validation :set_created_by_profile, if: -> { created_by_profile.blank? && created_by_user.present? }

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :process_and_product_share_node

  def source_node
    node_process&.node || skill_product&.node
  end

  private

    def set_created_by_profile
      self.created_by_profile = created_by_user.profile
    end

    def process_and_product_share_node
      return if node_process.blank? || skill_product.blank?
      return if node_process.node_id == skill_product.node.id

      errors.add(:skill_product, "deve appartenere allo stesso nodo del processo")
    end
end
