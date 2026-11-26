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
  belongs_to :brand_access, optional: true
  belongs_to :assigned_by_profile, class_name: "Profile", optional: true
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
      "#{User::ROLE_LABELS.fetch(role.to_s, role.to_s.humanize)} (#{display})"
    end
  end

  validates :role, presence: true
  validates :status, presence: true, inclusion: { in: %w[active suspended revoked] }
  validates :role, uniqueness: { scope: [ :profile_id, :context_type, :context_id, :parent_id ] }, unless: :operator?
  validates :role_operator, presence: true, uniqueness: { scope: [ :profile_id, :context_type, :context_id ], case_sensitive: false }, if: :operator?
  validate :context_fields_match
  validate :parent_role_assignment_constraints
  validate :operator_assignment_matches_brand
  validate :brand_access_matches_assignment, if: -> { brand_access.present? && status != "revoked" }

  before_validation :normalize_role_operator

  scope :global, -> { where(context_type: nil, context_id: nil) }
  scope :for_context, ->(context) { where(context: context) }
  scope :active, -> { where(status: "active") }
  scope :currently_effective, ->(at = Time.current) {
    active.where("starts_at IS NULL OR starts_at <= ?", at)
      .where("ends_at IS NULL OR ends_at > ?", at)
  }

  def effective_for_access?(access, at: Time.current)
    return false unless operator? && status == "active" && access&.active?
    return false unless brand_access_id == access.id && profile_id == access.profile_id
    return false if (starts_at && starts_at > at) || (ends_at && ends_at <= at)
    return false unless RoleDefinitions::Registry.assignable_to?(role_operator, brand_node: access.brand_node, node: context)

    context.site_node == access.brand_node
  end

  private

    def normalize_role_operator
      self.role_operator = RoleDefinitions::Registry.canonical_code(role_operator)
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
      return unless operator? && status != "revoked"

      unless context.is_a?(Node)
        errors.add(:context, "deve essere un Brand")
        return
      end

      errors.add(:parent, "deve essere l'ideatore del Brand") if parent != context.role_assignment

      role_allowed = if brand_access.present?
        RoleDefinitions::Registry.assignable_to?(role_operator, brand_node: brand_access.brand_node, node: context)
      else
        context.operator_role?(role_operator)
      end
      unless role_allowed
        errors.add(:role_operator, "non è previsto per questo Brand")
      end
    end

    def brand_access_matches_assignment
      errors.add(:brand_access, "deve appartenere allo stesso profilo") if brand_access.profile_id != profile_id
      errors.add(:brand_access, "deve essere attivo") unless brand_access.active?
      return unless context.is_a?(Node)
      return if context == brand_access.brand_node || context.ancestors.exists?(brand_access.brand_node_id)

      errors.add(:brand_access, "non comprende il Node del ruolo")
    end
end
