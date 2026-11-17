# Il Content su una piattaforma (sito, YouTube, Substack…). Piattaforma, URL e testo adattato
# arrivano dal YAML; lo stato di pubblicazione lo scrivono gli impegni conclusi.
class ContentPublication < ApplicationRecord
  PLATFORMS = %w[sito youtube instagram vimeo substack linkedin x].freeze
  FORMATS = %w[articolo post newsletter video reel short thread live].freeze

  belongs_to :content, inverse_of: :publications
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", inverse_of: :content_publication,
           dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: { scope: :content_id }
  validates :platform, inclusion: { in: PLATFORMS }
  validates :format, inclusion: { in: FORMATS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :publication_status, inclusion: { in: Content::PUBLICATION_STATUSES }
  validates :publication_visibility, inclusion: { in: Content::PUBLICATION_VISIBILITIES }
end
