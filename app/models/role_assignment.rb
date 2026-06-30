class RoleAssignment < ApplicationRecord
  ROOT_ROLES = %w[creator_of_worlds demo].freeze

  enum :role, {
    teacher: 0,
    tutor: 1,
    professional: 2,   
    segreteria_clienti: 3,
    responsabile_centro: 4,
    segreteria_amministrativa: 5,
    creator_of_worlds: 6,
    demo: 8
  }

  def role=(val)
    mapped_val = case val&.to_s
                 when "creator" then "creator_of_worlds"
                 when "admin" then "segreteria_amministrativa"
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
                user&.email_address&.split('@')&.first
              end

    if role == "creator_of_worlds"
      "Creator (#{display})"
    else
      "#{role.to_s.humanize} (#{display})"
    end
  end

  validates :role, presence: true
  validates :role, uniqueness: { scope: [ :profile_id, :context_type, :context_id, :parent_id ] }
  validate :context_fields_match
  validate :parent_role_assignment_constraints

  scope :global, -> { where(context_type: nil, context_id: nil) }
  scope :for_context, ->(context) { where(context: context) }

  private

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
        elsif !parent&.creator_of_worlds?
          errors.add(:parent_id, "deve fare riferimento a un ruolo 'creator_of_worlds'")
        end
      end
    end
end
