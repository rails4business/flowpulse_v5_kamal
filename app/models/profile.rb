class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :primary_node, class_name: "Node", optional: true, inverse_of: :primary_professional_profile
  has_many :role_assignments, dependent: :destroy
  has_many :brand_accesses, dependent: :destroy
  has_many :submitted_brand_requests,
           class_name: "BrandRequest",
           foreign_key: :requester_profile_id,
           dependent: :nullify
  has_many :assigned_brand_requests,
           class_name: "BrandRequest",
           foreign_key: :assigned_to_profile_id,
           dependent: :nullify
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :destroy
  has_many :created_data_commitments,
           class_name: "Brands::Impegno::Commitment",
           foreign_key: :created_by_profile_id,
           inverse_of: :created_by_profile,
           dependent: :restrict_with_error
  has_many :assigned_data_commitments, class_name: "Brands::Impegno::Commitment", foreign_key: :assignee_profile_id, dependent: :nullify
  has_many :responsible_data_commitments, class_name: "Brands::Impegno::Commitment", foreign_key: :responsible_profile_id, dependent: :nullify
  has_many :impegno_contacts, class_name: "Brands::Impegno::Contact", dependent: :destroy
  has_many :impegno_places, class_name: "Brands::Impegno::Place", dependent: :destroy
  has_many :data_commitment_imports, foreign_key: :target_profile_id, dependent: :nullify
  has_many :problem_solving_cycles,
           foreign_key: :owner_profile_id,
           inverse_of: :owner_profile,
           dependent: :destroy
  has_many :reusable_skills,
           foreign_key: :owner_profile_id,
           inverse_of: :owner_profile,
           dependent: :destroy
  has_many :created_skill_products,
           class_name: "SkillProduct",
           foreign_key: :created_by_profile_id,
           inverse_of: :created_by_profile,
           dependent: :restrict_with_error
  has_many :created_node_processes,
           class_name: "NodeProcess",
           foreign_key: :created_by_profile_id,
           dependent: :nullify
  has_many :responsible_node_processes,
           class_name: "NodeProcess",
           foreign_key: :responsible_profile_id,
           dependent: :nullify
  has_many :created_data_experiences,
           class_name: "DataExperience",
           foreign_key: :created_by_profile_id,
           dependent: :nullify
  has_many :responsible_data_experiences,
           class_name: "DataExperience",
           foreign_key: :responsible_profile_id,
           dependent: :nullify
  has_many :created_data_sessions,
           class_name: "DataSession",
           foreign_key: :created_by_profile_id,
           dependent: :nullify
  has_many :created_data_slots,
           class_name: "DataSlot",
           foreign_key: :created_by_profile_id,
           dependent: :nullify

  validates :user_id, uniqueness: true
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "può contenere solo lettere, numeri e underscore (_)" },
                       length: { minimum: 3, maximum: 30 }
  validate :primary_node_is_professional

  before_validation :set_default_username, on: :create
  before_validation :normalize_username

  private

    def set_default_username
      return if username.present?

      base = if user&.email_address.present?
               user.email_address.split("@").first.downcase.gsub(/[^a-z0-9_]/, "_")[0...30]
      elsif display_name.present?
               display_name.downcase.gsub(/[^a-z0-9_]/, "_")[0...30]
      else
               "user"
      end

      base = "user" if base.blank?

      username_val = base
      counter = 1
      while Profile.exists?(username: username_val)
        suffix = "_#{counter}"
        username_val = "#{base[0...(30 - suffix.length)]}#{suffix}"
        counter += 1
      end
      self.username = username_val
    end

    def normalize_username
      self.username = username.to_s.strip.downcase if username.present?
    end

    def primary_node_is_professional
      return if primary_node.blank? || primary_node.professional?

      errors.add(:primary_node, "deve essere un nodo professionale")
    end
end
