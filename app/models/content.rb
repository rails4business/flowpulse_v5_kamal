# Contenuto editoriale indipendente dalla piattaforma: articolo, corso, capitolo o scheda.
# Struttura e testo arrivano dai YAML con l'import; lo stato di pubblicazione è dell'ambiente
# e lo scrivono soltanto gli impegni di pubblicazione conclusi.
class Content < ApplicationRecord
  FORMATS = %w[course chapter post insegnante professionista founder centro scuola metodica].freeze
  PUBLICATION_STATUSES = Brands::Impegno::Commitment::PUBLICATION_STATUSES
  PUBLICATION_VISIBILITIES = Brands::Impegno::Commitment::PUBLICATION_VISIBILITIES
  ACCESS_MODES = Brands::Impegno::Commitment::ACCESS_MODES

  belongs_to :node, inverse_of: :editorial_contents
  belongs_to :parent, class_name: "Content", optional: true, inverse_of: :children
  has_many :children, -> { order(:position, :id) }, class_name: "Content", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :restrict_with_error
  has_many :publications, -> { order(:position, :id) }, class_name: "ContentPublication",
           inverse_of: :content, dependent: :destroy
  has_many :contributions, -> { order(:position, :id) }, class_name: "ContentContribution",
           inverse_of: :content, dependent: :destroy
  has_many :outgoing_links, class_name: "ContentLink", foreign_key: :source_content_id,
           inverse_of: :source_content, dependent: :destroy
  has_many :incoming_links, class_name: "ContentLink", foreign_key: :target_content_id,
           inverse_of: :target_content, dependent: :destroy
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", inverse_of: :content,
           dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: { scope: [:node_id, :parent_id] }
  validates :title, presence: true
  validates :format, inclusion: { in: FORMATS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :publication_status, inclusion: { in: PUBLICATION_STATUSES }
  validates :publication_visibility, inclusion: { in: PUBLICATION_VISIBILITIES }
  validate :access_modes_are_valid
  validate :parent_is_not_self

  def published_for_public?
    publication_status == "published" && publication_visibility == "public"
  end

  private

    def access_modes_are_valid
      invalid = Array(access_modes) - ACCESS_MODES
      errors.add(:access_modes, "contiene valori non ammessi: #{invalid.join(', ')}") if invalid.any?
    end

    def parent_is_not_self
      errors.add(:parent, "non può essere il contenuto stesso") if parent_id.present? && parent_id == id
    end
end
