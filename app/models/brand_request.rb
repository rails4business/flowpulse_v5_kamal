class BrandRequest < ApplicationRecord
  KINDS = %w[
    waitlist access group_path individual_treatment event events service
    information training find_professional professional_application contact other
  ].freeze
  AUDIENCES = %w[user professional organization].freeze
  ACTIVE_STATUSES = %w[open in_progress waiting invited].freeze
  CLOSED_STATUSES = %w[accepted closed rejected cancelled].freeze
  STATUSES = (ACTIVE_STATUSES + CLOSED_STATUSES).freeze

  belongs_to :domain
  belongs_to :brand_node, class_name: "Node"
  belongs_to :requester_profile, class_name: "Profile", optional: true
  belongs_to :participant_contact, class_name: "Brands::Impegno::Contact", optional: true,
             inverse_of: :brand_requests
  belongs_to :assigned_to_profile, class_name: "Profile", optional: true
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :legacy_data_commitment, class_name: "Brands::Impegno::Commitment", optional: true

  has_many :brand_invitations, dependent: :nullify
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :nullify

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :audience, inclusion: { in: AUDIENCES }
  validates :status, inclusion: { in: STATUSES }
  validate :domain_belongs_to_brand
  validate :requester_or_contact_present
  validate :contact_has_a_channel

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :closed, -> { where(status: CLOSED_STATUSES) }

  def active?
    status.in?(ACTIVE_STATUSES)
  end

  def close_as!(target_status)
    raise ArgumentError, "Stato finale non valido" unless target_status.to_s.in?(CLOSED_STATUSES)

    update!(status: target_status, resolved_at: Time.current)
  end

  private

    def domain_belongs_to_brand
      return if domain.blank? || brand_node.blank?
      return if domain.canonical_domain_record&.node_id == brand_node_id

      errors.add(:domain, "deve appartenere al Brand destinatario")
    end

    def requester_or_contact_present
      return if requester_profile.present? || participant_contact.present?

      errors.add(:base, "La richiesta deve avere una persona o un contatto")
    end

    def contact_has_a_channel
      return if participant_contact.blank?
      return if participant_contact.email.present? || participant_contact.phone.present?

      errors.add(:participant_contact, "deve avere almeno un indirizzo email o un numero di telefono")
    end
end
