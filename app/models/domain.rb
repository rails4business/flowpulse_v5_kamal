class Domain < ApplicationRecord
  store_accessor :settings, :logo_full_url, :logo_square_url

  belongs_to :role_assignment, optional: true
  belongs_to :node, optional: true
  has_many :traveler_subscriptions, dependent: :destroy

  before_validation :normalize_hosts
  before_validation :normalize_brand_settings
  before_validation :sync_role_assignment_from_node


  validates :hostname, presence: true, uniqueness: true
  validates :locale, presence: true
  validate :target_controller_and_action_presence
  validate :role_assignment_is_creator_world
  validate :node_belongs_to_role_assignment

  scope :active, -> { where(active: true) }

  def self.find_for_host(host)
    active.find_by(hostname: normalize_host(host))
  end

  def self.import_from_config!(environment = Rails.env)
    import_from_hash!(Rails.application.config_for(:domains, env: environment))
  end

  def self.import_from_hash!(domains_config)
    domains_config.each do |hostname, config|
      attrs = config.with_indifferent_access

      find_or_initialize_by(hostname: hostname).tap do |domain|
        domain.canonical_host = attrs[:canonical_host]
        domain.locale = attrs[:locale].presence || "it"
        domain.target_controller = attrs[:target_controller]
        domain.target_action = attrs[:target_action]
        domain.primary = ActiveModel::Type::Boolean.new.cast(attrs.fetch(:primary, false))
        domain.active = ActiveModel::Type::Boolean.new.cast(attrs.fetch(:active, true))
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
    order(:hostname).pluck(:hostname, :canonical_host, :locale, :primary, :active, :target_controller, :target_action, :settings).each_with_object({}) do |row, hash|
      hostname, canonical_host, locale, primary, active, target_controller, target_action, settings = row

      config = {}
      config["canonical_host"] = canonical_host if canonical_host.present?
      config["locale"] = locale if canonical_host.blank?
      config["target_controller"] = target_controller if target_controller.present?
      config["target_action"] = target_action if target_action.present?
      config["primary"] = true if primary
      config["active"] = false unless active
      config.merge!(settings.to_h) if settings.present?

      hash[hostname] = config
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
      self.logo_full_url = logo_full_url.to_s.strip.presence
      self.logo_square_url = logo_square_url.to_s.strip.presence
      self.settings = settings.to_h.compact.presence
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

    def role_assignment_is_creator_world
      return if role_assignment.blank?
      return if role_assignment.creator_of_worlds?

      errors.add(:role_assignment_id, "deve fare riferimento a un ruolo creator_of_worlds")
    end

    def node_belongs_to_role_assignment
      return if node.blank? || role_assignment.blank?
      return if node.role_assignment_id == role_assignment_id

      errors.add(:node_id, "deve appartenere allo stesso Creator del dominio")
    end
end
