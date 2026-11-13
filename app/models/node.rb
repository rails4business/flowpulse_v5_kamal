class Node < ApplicationRecord
  enum :node_type, { professional: 0, project: 1 }, default: :project

  STATUSES = %w[draft published archived].freeze
  VISIBILITIES = %w[public subscription member private].freeze
  VISIBILITY_LABELS = {
    "public" => "Pubblico",
    "subscription" => "Iscrizione gratuita",
    "private" => "Privato",
    "member" => "Member"
  }.freeze

  belongs_to :role_assignment
  belongs_to :parent, class_name: "Node", optional: true
  belongs_to :link_node, class_name: "Node", optional: true
  belongs_to :professional_owner_node, class_name: "Node", optional: true
  has_closure_tree order: "position", dependent: :destroy

  has_many :domains, dependent: :nullify
  has_many :services, dependent: :restrict_with_error
  has_many :node_processes, dependent: :restrict_with_error
  has_many :node_events, dependent: :destroy
  has_many :metro_map_placements, dependent: :destroy
  has_many :problem_solving_cycle_nodes, dependent: :destroy
  has_many :problem_solving_cycles, through: :problem_solving_cycle_nodes
  has_many :reusable_skill_nodes, dependent: :destroy
  has_many :reusable_skills, through: :reusable_skill_nodes
  has_many :context_professional_calendars,
    class_name: "ProfessionalCalendar",
    foreign_key: :context_node_id,
    dependent: :restrict_with_error,
    inverse_of: :context_node
  has_many :professional_calendars,
    class_name: "ProfessionalCalendar",
    foreign_key: :professional_node_id,
    dependent: :restrict_with_error,
    inverse_of: :professional_node
  has_many :brand_accesses,
           foreign_key: :brand_node_id,
           inverse_of: :brand_node,
           dependent: :destroy
  has_many :brand_requests,
    foreign_key: :brand_node_id,
    inverse_of: :brand_node,
    dependent: :restrict_with_error
  has_many :professionally_owned_nodes,
    class_name: "Node",
    foreign_key: :professional_owner_node_id,
    dependent: :nullify,
    inverse_of: :professional_owner_node
  has_one :primary_professional_profile,
    class_name: "Profile",
    foreign_key: :primary_node_id,
    dependent: :nullify,
    inverse_of: :primary_node
  has_one :content,
    class_name: "NodeContent",
    dependent: :destroy,
    inverse_of: :node

  acts_as_list scope: [:parent_id, :role_assignment_id]

  accepts_nested_attributes_for :content, update_only: true

  attr_writer :navigation_mode

  before_validation :normalize_line_and_offer_slugs

  before_validation :apply_navigation_form

  before_validation :set_slug, if: -> { slug.blank? && title.present? }
  before_validation :set_node_defaults
  before_validation :normalize_operator_roles
  before_validation :inherit_role_assignment_from_parent
  after_initialize :build_default_content, if: :new_record?
  after_save :sync_descendant_role_assignments, if: :saved_change_to_role_assignment_id?
  after_save :sync_domain_role_assignments, if: :saved_change_to_role_assignment_id?

  validates :title, presence: true
  validates :slug, presence: true
  validates :role_assignment, presence: true
  validates :node_type, presence: true
  validates :view_type, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :map_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "deve essere un colore HEX nel formato #RRGGBB" }, allow_blank: true
  validate :operator_roles_are_valid
  validate :role_assignment_matches_parent
  validate :validate_link_node_constraints
  validate :parent_cannot_be_bridge_node
  validate :professional_owner_is_professional
  validate :navigation_items_are_valid

  scope :published_public, -> { where(status: "published", visibility: "public") }
  scope :published_free, -> { where(status: "published", visibility: %w[public subscription]) }
  scope :lane_containers, -> { where(lane_container: true) }

  def line_slugs_input
    line_slugs.join("\n")
  end

  def line_slugs_input=(value)
    self.line_slugs = split_reference_slugs(value)
  end

  def offer_slugs_input
    offer_slugs.join("\n")
  end

  def offer_slugs_input=(value)
    self.offer_slugs = split_reference_slugs(value)
  end

  def lane_column?
    lane_container? || domains.active.exists?
  end

  def self.visibility_label(visibility)
    VISIBILITY_LABELS.fetch(visibility.to_s, visibility.to_s.humanize)
  end

  def resolve_target
    visited = []
    current = self
    while current.link_node_id.present?
      break if visited.include?(current.link_node_id)
      visited << current.link_node_id
      current = current.link_node
    end
    current
  end

  def bridge_node?
    link_node_id.present?
  end

  def operator_role?(role_code)
    operator_roles.include?(role_code.to_s)
  end

  # Il contesto preciso può essere un progetto interno. Il sito/Brand si ricava
  # risalendo fino al primo Node che possiede almeno un Domain attivo.
  def site_node
    current = self
    while current.present?
      return current if current.domains.active.exists?

      current = current.parent
    end
  end

  def brand?
    domains.active.exists?
  end

  def primary_domain
    domains.active.where(primary: true, canonical_host: [nil, ""]).first
  end

  def navigation_mode
    return @navigation_mode if defined?(@navigation_mode)
    return "inherit" if navigation.nil?

    Array(navigation["items"]).empty? ? "none" : "custom"
  end

  def navigation_input
    return @navigation_input if defined?(@navigation_input)
    return "" unless navigation_mode == "custom"

    navigation_items_to_hash(Array(navigation["items"])).to_yaml.delete_prefix("---\n")
  end

  def navigation_input=(value)
    @navigation_input_assigned = true
    @navigation_input = value.to_s
  end

  def navigation_source_node
    self_and_ancestors.find { |candidate| !candidate.navigation.nil? }
  end

  def effective_navigation_items
    source = navigation_source_node
    source ? Array(source.navigation["items"]) : []
  end

  def owned_by?(user)
    user.present? && role_assignment&.user == user
  end

  def administered_by?(user)
    return false unless user
    return true if user.superadmin_user? || owned_by?(user)
    return true if professional? && primary_professional_profile&.user == user
    return true if professional_owner_node&.owned_by?(user)
    return false unless user.profile

    RoleAssignment.where(profile: user.profile, context: self, role: %i[admin responsabile]).exists?
  end

  def cell_status
    case node_events.where(kind: %w[started consolidated cut resumed]).order(happened_at: :desc, id: :desc).pick(:kind)
    when "started", "resumed" then "active"
    when "consolidated" then "consolidated"
    when "cut" then "cut"
    else "idea"
    end
  end

  private

  def normalize_line_and_offer_slugs
    self.line_slugs = normalize_reference_slugs(line_slugs)
    self.offer_slugs = normalize_reference_slugs(offer_slugs)
  end

  def split_reference_slugs(value)
    normalize_reference_slugs(value.to_s.split(/[\s,]+/))
  end

  def normalize_reference_slugs(values)
    Array(values).filter_map { |value| value.to_s.strip.downcase.presence }.uniq
  end

  def apply_navigation_form
    return unless defined?(@navigation_mode) || @navigation_input_assigned

    case navigation_mode
    when "inherit"
      self.navigation = nil
    when "none"
      self.navigation = { "items" => [] }
    when "custom"
      parsed = YAML.safe_load(@navigation_input.to_s, permitted_classes: [], permitted_symbols: [], aliases: false)
      parsed = {} if parsed.nil?
      unless parsed.is_a?(Hash)
        errors.add(:navigation, "deve essere un hash YAML di slug e nomi")
        return
      end
      self.navigation = { "items" => normalize_navigation_hash(parsed) }
    else
      errors.add(:navigation, "ha una modalità non valida")
    end
  rescue Psych::SyntaxError => error
    errors.add(:navigation, "contiene YAML non valido: #{error.problem}")
  end

  def normalize_navigation_hash(raw)
    raw.map do |key, definition|
      key = key.to_s.strip
      if definition.is_a?(Hash)
        attributes = definition.stringify_keys
        item = {
          "key" => key,
          "label" => attributes["label"].to_s.strip.presence || key.humanize
        }
        item["group"] = true if ActiveModel::Type::Boolean.new.cast(attributes["group"])
        item["home"] = true if ActiveModel::Type::Boolean.new.cast(attributes["home"])
        item["path"] = attributes["path"].to_s.strip if attributes["path"].present?
        item["audience"] = attributes["audience"].to_s.strip if attributes["audience"].present?
        item["slug"] = attributes["slug"].to_s.strip.presence || key unless item["group"] || item["home"] || item["path"].present?
        children = attributes["children"]
        item["children"] = normalize_navigation_hash(children) if children.is_a?(Hash)
        item
      else
        { "key" => key, "slug" => key, "label" => definition.to_s.strip.presence || key.humanize }
      end
    end
  end

  def navigation_items_to_hash(items)
    items.each_with_object({}) do |item, hash|
      children = Array(item["children"])
      key = item["key"].presence || item["slug"]
      attributes = {
        "label" => item["label"],
        "slug" => item["slug"].presence == key ? nil : item["slug"].presence,
        "group" => item["group"] ? true : nil,
        "home" => item["home"] ? true : nil,
        "path" => item["path"].presence,
        "audience" => item["audience"].presence,
        "children" => children.any? ? navigation_items_to_hash(children) : nil
      }.compact
      hash[key] = if attributes.keys == ["label"]
        item["label"]
      else
        attributes
      end
    end
  end

  def navigation_items_are_valid
    return if navigation.nil?

    items = navigation["items"]
    unless items.is_a?(Array)
      errors.add(:navigation, "deve contenere un elenco ordinato di voci")
      return
    end

    validate_navigation_level(items)
  end

  def validate_navigation_level(items)
    keys = items.filter_map { |item| (item["key"].presence || item["slug"]).to_s.strip.presence }
    errors.add(:navigation, "contiene identificatori duplicati") if keys.uniq.size != keys.size

    items.each do |item|
      key = (item["key"].presence || item["slug"]).to_s.strip
      slug = item["slug"].to_s.strip
      label = item["label"].to_s.strip
      path = item["path"].to_s.strip
      group = item["group"] == true
      home = item["home"] == true
      audience = item["audience"].presence || "public"
      errors.add(:navigation, "contiene una voce senza identificatore") if key.blank?
      errors.add(:navigation, "contiene una voce senza nome") if label.blank?
      errors.add(:navigation, "contiene un pubblico non valido per #{key}") unless audience.in?(%w[public superadmin])
      errors.add(:navigation, "contiene un percorso non valido per #{key}") if path.present? && !path.match?(%r{\A/(?!/)[^\s]*\z})
      target_count = [slug.present?, path.present?, group, home].count(true)
      errors.add(:navigation, "contiene una destinazione ambigua per #{key}") if target_count > 1
      errors.add(:navigation, "contiene una voce senza destinazione per #{key}") if target_count.zero?
      if slug.present? && role_assignment_id.present? && !Node.where(role_assignment_id: role_assignment_id, slug: slug).where.not(id: id).exists? && self.slug != slug
        errors.add(:navigation, "riferisce il Node inesistente #{slug}")
      end
      children = item["children"]
      validate_navigation_level(children) if children.is_a?(Array)
    end
  end

  def set_slug
    self.slug = title.parameterize
  end

  def set_node_defaults
    self.node_type = "project" if node_type.blank?
    self.view_type = "default" if view_type.blank?
    self.status = "draft" if status.blank?
    self.visibility = "public" if visibility.blank?
  end

  def normalize_operator_roles
    self.operator_roles = Array(operator_roles).filter_map { |role| role.to_s.strip.downcase.presence }.uniq
  end

  def operator_roles_are_valid
    invalid_roles = Array(operator_roles).reject { |role| role.match?(/\A[a-z0-9_]+\z/) }
    errors.add(:operator_roles, "contiene codici non validi: #{invalid_roles.join(', ')}") if invalid_roles.any?
  end

  def build_default_content
    build_content if content.blank?
  end

  def inherit_role_assignment_from_parent
    self.role_assignment ||= parent&.role_assignment
  end

  def role_assignment_matches_parent
    return if parent.blank?
    return if role_assignment_id.blank? || parent.role_assignment_id.blank?
    return if role_assignment_id == parent.role_assignment_id

    errors.add(:parent, "deve appartenere allo stesso Creatore")
  end

  def sync_descendant_role_assignments
    descendants.update_all(role_assignment_id: role_assignment_id, updated_at: Time.current)
  end

  def sync_domain_role_assignments
    domains.update_all(role_assignment_id: role_assignment_id, updated_at: Time.current)
  end

  def validate_link_node_constraints
    return if link_node_id.blank?

    if link_node_id == id
      errors.add(:link_node_id, "non può essere il nodo stesso")
    end

    if children.any?
      errors.add(:link_node_id, "non può essere impostato per un nodo che ha già dei figli")
    end

    if role_assignment_id.present? && link_node.present? && link_node.role_assignment_id != role_assignment_id
      errors.add(:link_node_id, "deve appartenere allo stesso Creatore")
    end

    # Verifica cicli circolari
    visited = [id]
    current = link_node
    while current.present?
      if visited.include?(current.id)
        errors.add(:link_node_id, "crea un ciclo/loop infinito di collegamenti")
        break
      end
      visited << current.id
      current = current.link_node
    end
  end

  def parent_cannot_be_bridge_node
    if parent.present? && parent.bridge_node?
      errors.add(:parent_id, "non può essere un nodo ponte (i nodi ponte non possono avere figli)")
    end
  end

  def professional_owner_is_professional
    return if professional_owner_node.blank?

    if professional_owner_node == self
      errors.add(:professional_owner_node, "non può essere il nodo stesso")
    elsif !professional_owner_node.professional?
      errors.add(:professional_owner_node, "deve essere un nodo professionale")
    end
  end
end
