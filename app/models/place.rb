# Luogo fisico (sede, studio, spazio all'aperto). Un luogo chiuso non si cancella: resta per la storia ma non
# compare tra i luoghi attivi. La pubblicazione (bozza/pubblicato, visibilità) è separata da aperto/chiuso e si
# modifica dall'admin dei luoghi. In ogni dominio può avere un Content che lo racconta (PlaceDomain).
class Place < ApplicationRecord
  STATUSES = %w[open closed].freeze

  belongs_to :created_by_profile, class_name: "Profile", optional: true
  has_many :place_domains, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :place
  has_many :domains, through: :place_domains

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :status, inclusion: { in: STATUSES }
  validates :publication_status, inclusion: { in: Content::PUBLICATION_STATUSES }
  validates :publication_visibility, inclusion: { in: Content::PUBLICATION_VISIBILITIES }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  scope :open, -> { where(status: "open") }
  scope :published_for_public, -> { where(publication_status: "published", publication_visibility: "public") }
  # I luoghi aperti e pubblici collegati a un dominio: quelli che il sito del dominio mostra.
  scope :shown_on, ->(domain) { open.published_for_public.where(id: PlaceDomain.where(domain:).select(:place_id)) }

  before_save :set_published_at

  def open?
    status == "open"
  end

  def published?
    publication_status == "published"
  end

  def directions_url
    metadata.to_h["directions_url"]
  end

  def directions_url=(value)
    self.metadata = metadata.to_h.merge("directions_url" => value.presence).compact
  end

  # Content che possono raccontare il luogo in un dominio: quelli del node del dominio e dei suoi discendenti.
  def self.content_choices_for(domain)
    root = domain.resolved_node
    return Content.none unless root

    Content.where(node_id: root.self_and_descendants.select(:id)).order(:title)
  end

  private

    # Alla prima pubblicazione la data è quella del momento, se non è stata indicata.
    def set_published_at
      self.published_at ||= Time.current if published?
    end
end
