module Brands
  module Impegno
    class Commitment < ApplicationRecord
      self.table_name = "data_commitments"

      # Mantiene param_key, route_key e nomi dei form compatibili durante la migrazione.
      def self.model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "DataCommitment")
      end
  KINDS = %w[personal appointment event project path content academy work service purchase report].freeze
  STATUSES = %w[draft requested planned confirmed in_progress completed cancelled].freeze
  PRICING_TYPES = %w[hourly fixed none].freeze
  CONTRIBUTION_TYPES = %w[time_investment money_investment paid unpaid].freeze
  PUBLICATION_STATUSES = %w[draft published archived].freeze
  PUBLICATION_VISIBILITIES = %w[public member private].freeze
  ACCESS_MODES = %w[free subscription purchase].freeze
  PUBLICATION_CHANGE_KINDS = %w[publish update fix unpublish archive].freeze
  WORKBENCH_ITEM_TYPES = %w[undecided activity project skill product event recurring_event].freeze
  WORKBENCH_ORGANIZATIONS = %w[undecided todo dated_event recurring_event production_chain].freeze
  WORKBENCH_CLASSIFICATION_STATUSES = %w[unclassified partial ready].freeze

  belongs_to :profile
  belongs_to :created_by_profile, class_name: "Profile", inverse_of: :created_data_commitments
  belongs_to :domain
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :assignee_profile, class_name: "Profile", optional: true
  belongs_to :responsible_profile, class_name: "Profile", optional: true
  belongs_to :published_by_profile, class_name: "Profile", optional: true
  belongs_to :previous_publication_commitment, class_name: "Brands::Impegno::Commitment", optional: true
  belongs_to :participant_contact, class_name: "Brands::Impegno::Contact", optional: true,
             inverse_of: :participant_data_commitments
  belongs_to :parent, class_name: "Brands::Impegno::Commitment", optional: true, inverse_of: :children
  belongs_to :data_experience, optional: true
  belongs_to :data_session, optional: true
  belongs_to :data_slot, optional: true
  belongs_to :skill_product, optional: true, inverse_of: :data_commitments
  belongs_to :brand_request, optional: true, inverse_of: :data_commitments
  belongs_to :content, optional: true, inverse_of: :data_commitments
  belongs_to :content_publication, optional: true, inverse_of: :data_commitments
  has_many :children, class_name: "Brands::Impegno::Commitment", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :restrict_with_error

  validates :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :starts_at, presence: true, unless: -> { experience_tree_draft? || external_request? || workbench_draft? }
  validates :calendar_key, :calendar_label, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :pricing_type, inclusion: { in: PRICING_TYPES }
  validates :contribution_type, inclusion: { in: CONTRIBUTION_TYPES }
  validates :publication_status, inclusion: { in: PUBLICATION_STATUSES }
  validates :publication_visibility, inclusion: { in: PUBLICATION_VISIBILITIES }
  validates :publication_change_kind, inclusion: { in: PUBLICATION_CHANGE_KINDS }, allow_blank: true
  validates :content_key, presence: true, if: :publication_requested?
  validates :hourly_rate, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :ends_after_start
  validate :actual_end_after_actual_start
  validate :calendar_interval_does_not_overlap
  validate :participant_contact_is_a_person
  validate :requested_contact_has_a_channel
  validate :access_modes_are_valid
  validate :free_access_is_exclusive
  validate :workbench_metadata_is_valid

  before_validation :normalize_access_modes
  before_validation :set_default_calendar_identity
  before_validation :calculate_hourly_total
  before_validation :assign_content_from_key
  before_validation :prepare_publication_decision, if: :publication_requested?
  before_validation :assign_previous_publication_commitment
  validate :content_matches_content_key

  after_commit :replay_content_publication_decisions, if: :publication_decision_affected?

  scope :for_genera_impresa_project, ->(slug) {
    where("genera_impresa @> ?", { project_slug: slug }.to_json)
  }
  scope :workbench_items, -> { where("metadata @> ?", { workbench: { inbox: true } }.to_json) }

  def workbench_item?
    ActiveModel::Type::Boolean.new.cast(workbench_data["inbox"])
  end

  def workbench_data
    metadata.to_h.fetch("workbench", {}).to_h
  end

  def duration_minutes
    if actual_started_at.present?
      return unless actual_ended_at.present?

      start_time = actual_started_at
      end_time = actual_ended_at
    else
      start_time = starts_at
      end_time = ends_at
    end
    return unless start_time && end_time

    ((end_time - start_time) / 60).round
  end

  def tracking?
    status == "in_progress" && actual_started_at.present? && actual_ended_at.blank?
  end

  def effective_interval
    if actual_started_at.present? && actual_ended_at.present?
      actual_started_at...actual_ended_at
    elsif starts_at.present? && ends_at.present?
      starts_at...ends_at
    end
  end

  def self.publication_status_for(change_kind)
    case change_kind
    when "archive" then "archived"
    when "unpublish" then "draft"
    else "published"
    end
  end

  def publication_requested?
    kind == "content" && publish_on_completion?
  end

  # Il Content indicato da content_key, solo se è uno e uno solo.
  # content_key è la chiave del Content; lo slug vale per i record storici: decisioni su contenuti senza id,
  # iscrizioni e completamenti salvati prima della chiave (il capitolo solo dentro metadata.course_slug).
  def matching_content
    return content_publication.content if content_publication
    return if content_key.blank?

    candidates = case metadata.to_h["record_type"]
    when "course_enrollment"
      content_by_key_or_slug(Content.where(format: "course", parent_id: nil))
    when "chapter_completion"
      chapters = Content.where(format: "chapter")
      content_by_key_or_slug(chapters, chapters.where(parent: Content.where(format: "course", slug: metadata.to_h["course_slug"])))
    else
      return unless kind == "content"

      content_by_key_or_slug(Content.all)
    end
    found = candidates.limit(2).to_a
    found.first if found.one?
  end

  def course_enrollment?
    metadata.to_h["record_type"] == "course_enrollment"
  end

  def chapter_completion?
    metadata.to_h["record_type"] == "chapter_completion"
  end

  # Lo slug attuale del corso (iscrizione) o del capitolo (completamento): quello del Content collegato,
  # altrimenti quello salvato quando l'impegno è nato.
  def learning_slug
    content&.slug || metadata.to_h[chapter_completion? ? "chapter_slug" : "course_slug"].presence || content_key
  end

  # Lo slug attuale del corso a cui appartiene l'iscrizione o il capitolo completato.
  def learning_course_slug
    (chapter_completion? ? content&.parent&.slug : content&.slug) || metadata.to_h["course_slug"]
  end

  def publication_decided_at
    published_at || actual_ended_at || updated_at
  end

  # Applica questa decisione sopra lo stato attuale; l'ordine lo decide Content#replay_publication_decisions!.
  def apply_publication_decision!
    decided_at = publication_decided_at
    target = content_publication || content
    attributes = { publication_status:, publication_visibility: }
    attributes[:access_modes] = access_modes if target.is_a?(Content)

    case publication_change_kind
    when "update", "fix"
      attributes[:published_at] = target.published_at || decided_at
      attributes[:revised_at] = decided_at if target.is_a?(Content)
    else
      attributes[:published_at] = publication_status == "published" ? decided_at : nil
    end

    target.update!(attributes)
  end

  private

    def normalize_access_modes
      self.access_modes = Array(access_modes).compact_blank.map(&:to_s).uniq
      self.access_modes = ["free"] if kind == "content" && access_modes.empty?
    end

    def access_modes_are_valid
      invalid_modes = access_modes - ACCESS_MODES
      errors.add(:access_modes, "contiene modalità non valide: #{invalid_modes.join(', ')}") if invalid_modes.any?
    end

    def free_access_is_exclusive
      return unless access_modes.include?("free") && access_modes.many?

      errors.add(:access_modes, "non può combinare l’accesso libero con abbonamento o acquisto")
    end

    def workbench_metadata_is_valid
      return unless workbench_item?

      validate_workbench_value("item_type", WORKBENCH_ITEM_TYPES)
      validate_workbench_value("organization", WORKBENCH_ORGANIZATIONS)
      validate_workbench_value("classification_status", WORKBENCH_CLASSIFICATION_STATUSES)
    end

    def validate_workbench_value(key, allowed_values)
      value = workbench_data[key].to_s
      return if allowed_values.include?(value)

      errors.add(:metadata, "contiene #{key} non valido")
    end

    def calculate_hourly_total
      return unless pricing_type == "hourly" && hourly_rate.present? && duration_minutes

      self.total_price = (duration_minutes / 60.0 * hourly_rate).round(2)
    end

    # content_key resta la chiave stabile del YAML; content_id è il collegamento nel database.
    def assign_content_from_key
      self.content_key = content.key if content && content_key.blank?
      self.content ||= matching_content
    end

    # I record storici salvano lo slug, che per loro fa da chiave.
    def content_matches_content_key
      if content && content_key.present? && !content_key.in?([content.key, content.slug])
        errors.add(:content_key, "non corrisponde al contenuto collegato")
      end
      if content_publication && content && content_publication.content_id != content.id
        errors.add(:content_publication, "appartiene a un altro contenuto")
      end
    end

    def concluding?
      status == "completed" && (new_record? || will_save_change_to_status?)
    end

    # Una decisione registrata già conclusa tiene lo stato indicato (o quello del tipo di cambiamento); una
    # decisione pianificata che si conclude prende lo stato dal tipo di cambiamento e la data di conclusione.
    def prepare_publication_decision
      return unless concluding?

      if new_record?
        self.publication_status = self.class.publication_status_for(publication_change_kind) if publication_status.blank?
        decided_at = published_at || Time.current
      else
        self.publication_status = self.class.publication_status_for(publication_change_kind)
        decided_at = actual_ended_at || Time.current
      end
      self.published_at = publication_status == "published" ? decided_at : nil
      self.blocks_calendar = false
    end

    # La decisione precedente sullo stesso contenuto e soggetto, fissata quando l'impegno nasce o si conclude.
    def assign_previous_publication_commitment
      return unless kind == "content" && content_key.present? && domain
      return if previous_publication_commitment_id.present?
      return unless new_record? || concluding?

      previous_scope = self.class.where(domain:, kind: "content", content_key:, subject:)
      previous_scope = previous_scope.where.not(id:) if persisted?
      self.previous_publication_commitment = previous_scope.order(created_at: :desc, id: :desc).first
    end

    # Una decisione conclusa che nasce, cambia o viene cancellata ricalcola lo stato del suo Content.
    def content_by_key_or_slug(scope, slug_scope = scope)
      by_key = scope.where(key: content_key)
      by_key.exists? ? by_key : slug_scope.where(slug: content_key)
    end

    def publication_decision_affected?
      publication_requested? && content.present? && (status == "completed" || status_before_last_save == "completed")
    end

    def replay_content_publication_decisions
      Content.find(content_id).replay_publication_decisions!
    end

    def ends_after_start
      return unless starts_at && ends_at && ends_at <= starts_at

      errors.add(:ends_at, "deve essere successiva all’inizio")
    end

    def actual_end_after_actual_start
      return unless actual_started_at && actual_ended_at && actual_ended_at <= actual_started_at

      errors.add(:actual_ended_at, "deve essere successiva all’inizio effettivo")
    end

    def set_default_calendar_identity
      return if profile.blank?

      self.assignee_profile ||= profile if calendar_key.blank?
      self.calendar_key ||= "profile:#{assignee_profile&.id || profile.id}"
      self.calendar_label ||= assignee_profile&.display_name.presence || assignee_profile&.username.presence || profile.display_name.presence || profile.username
    end

    def calendar_interval_does_not_overlap
      interval = effective_interval
      return unless blocks_calendar? && interval && status != "cancelled" && profile_id.present? && calendar_key.present?

      conflict = self.class.where(profile_id: profile_id, calendar_key: calendar_key, blocks_calendar: true)
        .where.not(status: "cancelled")
        .where.not(id: id)
        .find { |other| other.effective_interval && interval.begin < other.effective_interval.end && other.effective_interval.begin < interval.end }
      errors.add(:base, "Questo calendario contiene già un impegno nello stesso intervallo") if conflict
    end


    def participant_contact_is_a_person
      return if participant_contact.blank? || participant_contact.kind == "person"

      errors.add(:participant_contact, "deve essere una persona")
    end

    def requested_contact_has_a_channel
      return unless unscheduled_request?
      return if participant_contact&.email.present? || participant_contact&.phone.present?

      errors.add(:participant_contact, "deve avere almeno un indirizzo email o un numero di telefono")
    end

    def unscheduled_request?
      status == "requested" && !blocks_calendar? && participant_contact.present?
    end

    # Una richiesta proveniente da una persona esterna non diventa un evento di
    # calendario quando viene presa in carico o chiusa.
    def external_request?
      !blocks_calendar? && participant_contact.present?
    end

    def experience_tree_draft?
      data_experience_id.present? && starts_at.blank?
    end

    def workbench_draft?
      workbench_item? && status == "draft" && starts_at.blank? && !blocks_calendar?
    end
    end
  end
end
