module Brands
  module Impegno
    class Commitment < ApplicationRecord
      self.table_name = "data_commitments"

      # Mantiene param_key, route_key e nomi dei form compatibili durante la migrazione.
      def self.model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "DataCommitment")
      end
  KINDS = %w[personal appointment event project path content academy work service purchase report].freeze
  STATUSES = %w[draft planned confirmed in_progress completed cancelled].freeze
  PRICING_TYPES = %w[hourly fixed none].freeze
  CONTRIBUTION_TYPES = %w[time_investment money_investment paid unpaid].freeze

  belongs_to :profile
  belongs_to :created_by_profile, class_name: "Profile", inverse_of: :created_data_commitments
  belongs_to :domain
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :assignee_profile, class_name: "Profile", optional: true
  belongs_to :responsible_profile, class_name: "Profile", optional: true

  validates :title, :starts_at, presence: true
  validates :calendar_key, :calendar_label, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :pricing_type, inclusion: { in: PRICING_TYPES }
  validates :contribution_type, inclusion: { in: CONTRIBUTION_TYPES }
  validates :hourly_rate, :total_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :ends_after_start
  validate :actual_end_after_actual_start
  validate :calendar_interval_does_not_overlap

  before_validation :set_default_calendar_identity
  before_validation :calculate_hourly_total

  scope :for_genera_impresa_project, ->(slug) {
    where("genera_impresa @> ?", { project_slug: slug }.to_json)
  }

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

  private

    def calculate_hourly_total
      return unless pricing_type == "hourly" && hourly_rate.present? && duration_minutes

      self.total_price = (duration_minutes / 60.0 * hourly_rate).round(2)
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
    end
  end
end
