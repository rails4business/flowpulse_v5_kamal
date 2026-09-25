class Profile < ApplicationRecord
  belongs_to :user
  belongs_to :primary_node, class_name: "Node", optional: true, inverse_of: :primary_professional_profile
  has_many :role_assignments, dependent: :destroy
  has_many :traveler_subscriptions, dependent: :destroy
  has_many :domain_memberships, dependent: :destroy
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
