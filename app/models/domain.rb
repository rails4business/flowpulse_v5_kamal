class Domain < ApplicationRecord
  store_accessor :settings,
    :logo_full_url,
    :logo_square_url,
    :site_title,
    :site_description,
    :favicon_url,
    :social_image_url,
    :auth_slug,
    :auth_default_path,
    :auth_enabled,
    :operational_roles,
    :site_key

  belongs_to :role_assignment, optional: true
  belongs_to :node, optional: true
  has_many :traveler_subscriptions, dependent: :destroy
  has_many :domain_memberships, dependent: :destroy
  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :destroy

  before_validation :normalize_hosts
  before_validation :normalize_brand_settings
  before_validation :sync_role_assignment_from_node
  after_save :sync_operator_roles_to_node, if: -> { saved_change_to_settings? || saved_change_to_node_id? }


  validates :hostname, presence: true, uniqueness: true
  validates :locale, presence: true
  validate :target_controller_and_action_presence
  validate :role_assignment_is_creator_world
  validate :node_belongs_to_role_assignment
  validate :operational_roles_are_known

  scope :active, -> { where(active: true) }

  def self.find_for_host(host)
    normalized = normalize_host(host)
    domain = active.find_by(hostname: normalized)

    if domain&.canonical_host.present?
      primary = active.find_by(hostname: domain.canonical_host)
      return primary if primary
    end

    return domain if domain

    if normalized.start_with?("www.")
      active.find_by(hostname: normalized.sub(/\Awww\./, ""))
    else
      active.find_by(hostname: "www.#{normalized}")
    end
  end

  def self.import_from_config!(environment = Rails.env)
    import_from_hash!(Rails.application.config_for(:domains, env: environment))
  end

  def self.import_from_hash!(domains_config)
    domains_config.each do |hostname, config|
      attrs = config.with_indifferent_access
      node_slug = attrs.delete(:node_slug).presence

      find_or_initialize_by(hostname: hostname).tap do |domain|
        domain.canonical_host = attrs[:canonical_host]
        domain.locale = attrs[:locale].presence || "it"
        domain.target_controller = attrs[:target_controller]
        domain.target_action = attrs[:target_action]
        domain.primary = ActiveModel::Type::Boolean.new.cast(attrs.fetch(:primary, false))
        domain.active = ActiveModel::Type::Boolean.new.cast(attrs.fetch(:active, true))
        domain.node = Node.find_by!(slug: node_slug) if node_slug
        domain.settings = attrs.except(:canonical_host, :locale, :target_controller, :target_action, :primary, :active).presence
        domain.save!
      end
    end
  end

  def self.import_from_yaml!(yaml)
    parsed = YAML.safe_load(yaml.to_s, aliases: true) || {}
    domains_config = parsed[Rails.env] || parsed["default"] || parsed
    import_from_hash!(domains_config)
  end

  def self.export_to_hash
    includes(:node).order(:hostname).each_with_object({}) do |domain, hash|
      config = {}
      config["canonical_host"] = domain.canonical_host if domain.canonical_host.present?
      config["locale"] = domain.locale if domain.canonical_host.blank?
      config["target_controller"] = domain.target_controller if domain.target_controller.present?
      config["target_action"] = domain.target_action if domain.target_action.present?
      config["primary"] = true if domain.primary?
      config["active"] = false unless domain.active?
      config["node_slug"] = domain.node.slug if domain.node.present? && domain.canonical_host.blank?
      config.merge!(domain.settings.to_h) if domain.settings.present?

      hash[domain.hostname] = config
    end
  end

  def self.export_to_yaml
    YAML.dump({ "default" => export_to_hash })
  end

  def self.normalize_host(host)
    host.to_s.downcase.strip.split(":").first
  end

  def display_hostname
    hostname.to_s.sub(/\Awww\./, "")
  end

  def to_config
    {}.tap do |hash|
      hash["canonical_host"] = canonical_host if canonical_host.present?
      hash["locale"] = locale if canonical_host.blank?
      hash["target_controller"] = target_controller if target_controller.present?
      hash["target_action"] = target_action if target_action.present?
      hash["primary"] = primary if primary?
      hash["active"] = active unless active?
      hash.merge!(settings.to_h) if settings.present?
    end
  end

  private
    def normalize_hosts
      self.hostname = self.class.normalize_host(hostname)
      self.canonical_host = self.class.normalize_host(canonical_host) if canonical_host.present?
    end

    def normalize_brand_settings
      self.settings = settings.to_h
      raw_auth_enabled = auth_enabled
      self.logo_full_url = logo_full_url.to_s.strip.presence
      self.logo_square_url = logo_square_url.to_s.strip.presence
      self.site_title = site_title.to_s.strip.presence
      self.site_description = site_description.to_s.strip.presence
      self.favicon_url = favicon_url.to_s.strip.presence
      self.social_image_url = social_image_url.to_s.strip.presence
      self.auth_slug = auth_slug.to_s.strip.downcase.presence
      self.auth_default_path = auth_default_path.to_s.strip.presence
      self.auth_enabled = ActiveModel::Type::Boolean.new.cast(raw_auth_enabled) unless raw_auth_enabled.nil?
      self.site_key = site_key.to_s.strip.presence
      raw_operational_roles = operational_roles
      self.operational_roles = Array(raw_operational_roles).filter_map { |role| role.to_s.strip.presence }.uniq unless raw_operational_roles.nil?
      self.settings = settings.to_h.compact.presence
    end

    def operational_roles_are_known
      invalid_roles = Array(operational_roles).reject { |role| role.match?(/\A[a-z0-9_]+\z/) }
      errors.add(:operational_roles, "contiene codici non validi: #{invalid_roles.join(', ')}") if invalid_roles.any?
    end

    def target_controller_and_action_presence
      if target_controller.present? && target_action.blank?
        errors.add(:target_action, "deve essere presente se target_controller è presente")
      elsif target_action.present? && target_controller.blank?
        errors.add(:target_controller, "deve essere presente se target_action è presente")
      end
    end

    def sync_role_assignment_from_node
      if persisted? && role_assignment_id_changed? && role_assignment_id.blank?
        self.node = nil
      elsif node.present? && role_assignment.nil?
        self.role_assignment = node.role_assignment
      end
    end

    # Durante la transizione domains.yml conserva la lista iniziale; la fonte
    # effettiva diventa il Node/Brand a cui il dominio è collegato.
    def sync_operator_roles_to_node
      return if node.blank? || operational_roles.blank?

      node.update!(operator_roles: operational_roles)
    end

    def role_assignment_is_creator_world
      return if role_assignment.blank?
      return if role_assignment.ideatore?

      errors.add(:role_assignment_id, "deve fare riferimento a un ruolo ideatore")
    end

    def node_belongs_to_role_assignment
      return if node.blank? || role_assignment.blank?
      return if node.role_assignment_id == role_assignment_id

      errors.add(:node_id, "deve appartenere allo stesso Creator del dominio")
    end
end
