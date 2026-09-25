class RoleAssignment < ApplicationRecord
  ROOT_ROLES = %w[ideatore].freeze

  enum :role, {
    admin: 5,
    ideatore: 6,
    creator: 7,
    digital: 9,
    responsabile: 10,
    operator: 11
  }

  def role=(val)
    mapped_val = case val&.to_s
    when "creator_of_worlds" then "ideatore"
    when "segreteria_amministrativa" then "admin"
    else val
    end
    super(mapped_val)
  end

  belongs_to :profile
  delegate :user, to: :profile, allow_nil: true
  belongs_to :context, polymorphic: true, optional: true
  belongs_to :parent, class_name: "RoleAssignment", optional: true
  has_many :children, class_name: "RoleAssignment", foreign_key: :parent_id, dependent: :destroy

  has_many :nodes, dependent: :destroy
  has_many :node_domains, through: :nodes, source: :domains
  has_many :domains, dependent: :nullify

  def display_name
    display = if profile
                parts = [profile.display_name]
                parts << "@#{profile.username}" if profile.username.present?
                parts.compact.join(" - ")
    else
                user&.email_address&.split("@")&.first
    end

    if role == "ideatore"
      "Ideatore (#{display})"
    elsif operator?
      "#{role_operator.to_s.humanize} (#{display})"
    else
      "#{role.to_s.humanize} (#{display})"
    end
  end

  validates :role, presence: true
  validates :role, uniqueness: { scope: [ :profile_id, :context_type, :context_id, :parent_id ] }, unless: :operator?
  validates :role_operator, presence: true, uniqueness: { scope: [ :profile_id, :context_type, :context_id ], case_sensitive: false }, if: :operator?
  validate :context_fields_match
  validate :parent_role_assignment_constraints
  validate :operator_assignment_matches_brand

  before_validation :normalize_role_operator

  scope :global, -> { where(context_type: nil, context_id: nil) }
  scope :for_context, ->(context) { where(context: context) }

  private

    def normalize_role_operator
      self.role_operator = role_operator.to_s.strip.downcase.presence
    end

    def context_fields_match
      return if context_type.blank? && context_id.blank?
      return if context_type.present? && context_id.present?

      errors.add(:context, "deve avere sia type sia id")
    end

    def parent_role_assignment_constraints
      if ROOT_ROLES.include?(role.to_s)
        if parent_id.present?
          errors.add(:parent_id, "non può essere impostato per il ruolo #{role}")
        end
      else
        if parent_id.blank?
          errors.add(:parent_id, "deve essere impostato per i ruoli children")
        elsif !parent&.ideatore?
          errors.add(:parent_id, "deve fare riferimento a un ruolo 'ideatore'")
        end
      end
    end

    def operator_assignment_matches_brand
      return unless operator?

      unless context.is_a?(Node)
        errors.add(:context, "deve essere un Brand")
        return
      end

      errors.add(:parent, "deve essere l'ideatore del Brand") if parent != context.role_assignment

      unless context.operator_role?(role_operator)
        errors.add(:role_operator, "non è previsto per questo Brand")
      end
    end
end
