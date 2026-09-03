class DataEvent < ApplicationRecord
  CLASSIFICATIONS = %w[routine path class course event project].freeze
  NODE_KINDS = %w[root day session task].freeze
  STATUSES = %w[draft organizing proposed confirmed completed cancelled].freeze
  VISIBILITIES = %w[private public].freeze
  REGISTRATION_STATUSES = %w[pending open full closed].freeze
  REGISTRATION_MODES = %w[none required pending].freeze
  BOOKING_MODES = %w[none parent session individual_request].freeze
  SERVICE_SCOPES = %w[private domain brand].freeze

  belongs_to :parent, class_name: "DataEvent", optional: true, inverse_of: :children
  has_many :children, -> { order(:position, :id) },
           class_name: "DataEvent", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :restrict_with_error

  belongs_to :domain
  belongs_to :created_by_profile, class_name: "Profile", inverse_of: :created_data_events
  belongs_to :responsible_profile, class_name: "Profile", optional: true, inverse_of: :responsible_data_events
  belongs_to :place, class_name: "Brands::Impegno::Place", optional: true, inverse_of: :data_events
  belongs_to :service_data_event, class_name: "DataEvent", optional: true, inverse_of: :service_applications
  has_many :service_applications, class_name: "DataEvent", foreign_key: :service_data_event_id,
           inverse_of: :service_data_event, dependent: :restrict_with_error

  has_many :data_commitments, class_name: "Brands::Impegno::Commitment", dependent: :restrict_with_error
  has_many :requested_data_commitments, class_name: "Brands::Impegno::Commitment",
           foreign_key: :requested_data_event_id, dependent: :restrict_with_error

  validates :title, presence: true
  validates :classification, inclusion: { in: CLASSIFICATIONS }
  validates :node_kind, inclusion: { in: NODE_KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :registration_status, inclusion: { in: REGISTRATION_STATUSES }
  validates :registration_mode, inclusion: { in: REGISTRATION_MODES }
  validates :booking_mode, inclusion: { in: BOOKING_MODES }
  validates :service_scope, inclusion: { in: SERVICE_SCOPES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_cents, :duration_minutes, :minimum_participants, :maximum_participants,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :valid_parent_kind
  validate :parent_is_not_descendant
  validate :valid_intervals
  validate :session_is_inside_parent_window
  validate :service_reference_is_definition
  validate :participant_limits_are_coherent
  validate :draft_is_private
  validate :operator_roles_are_coherent
  validate :day_window_does_not_overlap_sibling

  scope :roots, -> { where(parent_id: nil, node_kind: "root") }
  scope :published, -> { where(visibility: "public").where.not(published_at: nil).where.not(status: "draft") }
  scope :chronological, -> { order(Arel.sql("starts_at ASC NULLS LAST"), :position, :id) }

  before_validation :inherit_classification

  def publish!(at: Time.current)
    raise ActiveRecord::RecordInvalid, self if draft?

    update!(visibility: "public", published_at: at)
  end

  def archived?
    archived_at.present?
  end

  def draft?
    status == "draft"
  end

  def effective_domain
    inherited_value(:domain)
  end

  def effective_responsible_profile
    inherited_value(:responsible_profile)
  end

  def effective_place
    inherited_value(:place)
  end

  def effective_service_data_event
    return self if service_definition?

    service_data_event || parent&.effective_service_data_event
  end

  def effective_operator_roles
    return normalized_operator_roles if normalized_operator_roles.any?

    inherited_roles = parent&.effective_operator_roles
    return inherited_roles if inherited_roles.present?

    service_data_event&.effective_operator_roles || []
  end

  def operator_role_for(profile)
    return if profile.blank?

    effective_operator_roles.find { |entry| entry["profile_id"] == profile.id }&.fetch("role", nil)
  end

  def organizer_profile
    effective_responsible_profile
  end

  def organizer_participation_role
    operator_role_for(organizer_profile)
  end

  def effective_maximum_participants
    maximum_participants || effective_service_data_event&.maximum_participants
  end

  def effective_price_cents
    price_cents.nil? ? effective_service_data_event&.price_cents : price_cents
  end

  def effective_currency
    return currency if price_cents.present?

    effective_service_data_event&.currency || currency
  end

  def effective_duration_minutes
    duration_minutes || effective_service_data_event&.duration_minutes
  end

  def confirmed_participants_count
    data_commitments.where(status: "confirmed", participation_role: "participant").count
  end

  def remaining_participant_places
    return unless effective_maximum_participants

    [effective_maximum_participants - confirmed_participants_count, 0].max
  end

  def participant_capacity_full?
    effective_maximum_participants.present? && remaining_participant_places.zero?
  end

  def refresh_registration_capacity!
    return unless effective_maximum_participants

    update!(registration_status: participant_capacity_full? ? "full" : "open")
  end

  def separately_bookable?
    service_definition? || service_data_event_id.present?
  end

  def root_event
    current = self
    current = current.parent while current.parent
    current
  end

  private

    def inherit_classification
      self.classification ||= parent&.classification
    end

    def inherited_value(attribute)
      public_send(attribute) || parent&.public_send("effective_#{attribute}")
    end

    def valid_parent_kind
      return if parent.blank?

      allowed_parent = { "day" => "root", "session" => "day", "task" => "session" }
      errors.add(:parent, "non è compatibile con il tipo di nodo") unless allowed_parent[node_kind] == parent.node_kind
    end

    def parent_is_not_descendant
      ancestor = parent
      while ancestor
        if ancestor.equal?(self) || (persisted? && ancestor.id == id)
          errors.add(:parent, "non può essere il nodo stesso o un suo discendente")
          break
        end
        ancestor = ancestor.parent
      end
    end

    def valid_intervals
      errors.add(:active_until, "deve essere uguale o successiva all'inizio") if active_from && active_until && active_until < active_from
      errors.add(:ends_at, "deve essere successiva all'inizio") if starts_at && ends_at && ends_at <= starts_at
      errors.add(:starts_at, "e fine devono appartenere alla stessa giornata") if starts_at && ends_at && starts_at.to_date != ends_at.to_date
      return unless node_kind == "session" && parent&.starts_at && starts_at
      return if parent.starts_at.to_date == starts_at.to_date

      errors.add(:starts_at, "deve appartenere al giorno padre")
    end

    def service_reference_is_definition
      return if service_data_event.blank? || service_data_event.service_definition?

      errors.add(:service_data_event, "deve essere una definizione di servizio")
    end

    def session_is_inside_parent_window
      return unless node_kind == "session" && parent&.starts_at && parent&.ends_at && starts_at && ends_at
      return if starts_at >= parent.starts_at && ends_at <= parent.ends_at

      errors.add(:starts_at, "e fine devono rientrare nella fascia giornaliera")
    end

    def participant_limits_are_coherent
      return unless minimum_participants && maximum_participants && minimum_participants > maximum_participants

      errors.add(:maximum_participants, "deve essere almeno pari al minimo")
    end

    def draft_is_private
      errors.add(:visibility, "deve essere privata per una bozza") if draft? && visibility == "public"
    end

    def normalized_operator_roles
      Array(operator_roles).filter_map do |entry|
        next unless entry.respond_to?(:stringify_keys)

        attributes = entry.stringify_keys
        profile_id = Integer(attributes["profile_id"], exception: false)
        next if profile_id.blank? || attributes["role"].to_s.blank?

        { "profile_id" => profile_id, "role" => attributes["role"].to_s }
      end
    end

    def operator_roles_are_coherent
      unless operator_roles.is_a?(Array) && normalized_operator_roles.size == operator_roles.size
        errors.add(:operator_roles, "deve contenere ruolo e profilo di ogni operatore")
        return
      end

      profile_ids = normalized_operator_roles.map { |entry| entry["profile_id"] }
      errors.add(:operator_roles, "non può ripetere lo stesso profilo") if profile_ids.uniq.size != profile_ids.size
    end

    def day_window_does_not_overlap_sibling
      return unless node_kind == "day" && parent_id.present? && starts_at.present? && ends_at.present?

      siblings = self.class.where(parent_id: parent_id, node_kind: "day").where.not(id: id)
      overlap = siblings.where("starts_at < ? AND ends_at > ?", ends_at, starts_at).exists?
      errors.add(:starts_at, "si sovrappone a un'altra fascia dello stesso giorno") if overlap
    end
end
