class RoleAssignment < ApplicationRecord
  enum :role, {
    creator: 0,
    teacher: 1,
    tutor: 2,
    professional: 3,
    admin: 4
  }

  belongs_to :user
  belongs_to :context, polymorphic: true, optional: true

  validates :role, presence: true
  validates :role, uniqueness: { scope: [ :user_id, :context_type, :context_id ] }
  validate :context_fields_match

  scope :global, -> { where(context_type: nil, context_id: nil) }
  scope :for_context, ->(context) { where(context: context) }

  private

    def context_fields_match
      return if context_type.blank? && context_id.blank?
      return if context_type.present? && context_id.present?

      errors.add(:context, "deve avere sia type sia id")
    end
end
