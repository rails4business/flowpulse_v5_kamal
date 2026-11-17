# Chi ha contribuito a un Content e con quale ruolo: un profilo, oppure un contatto
# inserito da qualcuno per conto di un professionista che non ha ancora un account.
class ContentContribution < ApplicationRecord
  ROLES = %w[autore esperto conduttore videomaker revisore editor soggetto].freeze

  belongs_to :content, inverse_of: :contributions
  belongs_to :profile, optional: true, inverse_of: :content_contributions
  belongs_to :contact, class_name: "Brands::Impegno::Contact", optional: true, inverse_of: :content_contributions

  validates :role, inclusion: { in: ROLES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :profile_id, uniqueness: { scope: [:content_id, :role] }, allow_nil: true
  validates :contact_id, uniqueness: { scope: [:content_id, :role] }, allow_nil: true
  validate :exactly_one_contributor

  def contributor
    profile || contact
  end

  private

    def exactly_one_contributor
      return if [profile_id, contact_id].compact.one?

      errors.add(:base, "Indica un profilo oppure un contatto, non entrambi")
    end
end
