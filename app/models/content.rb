# Contenuto editoriale indipendente dalla piattaforma: articolo, corso, capitolo o scheda.
# Il database è la fonte ufficiale di struttura, testo e stato editoriale. YAML e Markdown
# sono copie storiche/di sicurezza e fixture d'importazione. Gli impegni restano solo come storia.
class Content < ApplicationRecord
  FORMATS = %w[course chapter post insegnante professionista founder centro scuola metodica].freeze
  ROLES = %w[introduction chapter material attachment].freeze
  PLACEMENTS = %w[before_body after_body after_chapters].freeze
  EDITORS = %w[markdown lexxy].freeze
  SYNC_STATUSES = %w[clean markdown_changed lexxy_changed conflict].freeze
  PUBLICATION_STATUSES = Brands::Impegno::Commitment::PUBLICATION_STATUSES
  PUBLICATION_VISIBILITIES = Brands::Impegno::Commitment::PUBLICATION_VISIBILITIES
  ACCESS_MODES = Brands::Impegno::Commitment::ACCESS_MODES

  belongs_to :node, inverse_of: :editorial_contents
  # Titolare: chi gestisce il Content, anche dall'admin del proprio brand. Gli autori sono le contributions.
  belongs_to :profile, optional: true
  belongs_to :parent, class_name: "Content", optional: true, inverse_of: :children
  belongs_to :show_publication, class_name: "ContentPublication", optional: true
  has_rich_text :body
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
  has_many :place_domains, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: { scope: [:node_id, :parent_id] }
  validates :title, presence: true
  validates :format, inclusion: { in: FORMATS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :role, inclusion: { in: ROLES }
  validates :placement, inclusion: { in: PLACEMENTS }
  validates :editor, inclusion: { in: EDITORS }
  validates :sync_status, inclusion: { in: SYNC_STATUSES }
  validates :publication_status, inclusion: { in: PUBLICATION_STATUSES }
  validates :publication_visibility, inclusion: { in: PUBLICATION_VISIBILITIES }
  validate :access_modes_are_valid
  validate :parent_is_not_self
  validate :show_publication_belongs_to_content

  before_save :set_published_at
  before_validation :set_editorial_defaults

  scope :in_tree_of, ->(node) { where(node_id: node.self_and_descendants.select(:id)) }

  def published_for_public?
    publication_status == "published" && publication_visibility == "public"
  end

  # Impegni di pubblicazione conclusi: storia delle decisioni prese prima della modifica diretta.
  def publication_decisions
    data_commitments.where(kind: "content", publish_on_completion: true, status: "completed")
  end

  def published?
    publication_status == "published"
  end

  private

    def set_editorial_defaults
      self.role ||= case format
      when "course" then "introduction"
      when "chapter" then "chapter"
      else "material"
      end
      self.placement ||= (role == "chapter" ? "after_chapters" : "after_body")
    end

    # Alla prima pubblicazione la data è quella del momento, se non è stata indicata.
    def set_published_at
      self.published_at ||= Time.current if published?
    end

    def access_modes_are_valid
      invalid = Array(access_modes) - ACCESS_MODES
      errors.add(:access_modes, "contiene valori non ammessi: #{invalid.join(', ')}") if invalid.any?
    end

    def parent_is_not_self
      errors.add(:parent, "non può essere il contenuto stesso") if parent_id.present? && parent_id == id
    end

    def show_publication_belongs_to_content
      return if show_publication.blank? || show_publication.content_id == id

      errors.add(:show_publication, "deve appartenere allo stesso contenuto")
    end
end
