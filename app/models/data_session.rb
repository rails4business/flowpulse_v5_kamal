class DataSession < ApplicationRecord
  belongs_to :data_experience
  belongs_to :professional_calendar, optional: true
  belongs_to :service, optional: true
  has_many :data_slots, dependent: :restrict_with_error
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :restrict_with_error

  validates :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :visibility, inclusion: { in: %w[public private] }
  validates :professional_calendar, presence: true, if: :public_calendar_entry?
  validate :ends_after_start

  private

    def ends_after_start
      return unless starts_at && ends_at && ends_at <= starts_at

      errors.add(:ends_at, "deve essere successiva all’inizio")
    end

    def public_calendar_entry?
      visibility == "public"
    end
end
