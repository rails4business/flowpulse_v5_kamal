require "digest"

class DataCommitmentTransfer
  SCHEMA = "data_commitments/v1".freeze
  ATTRIBUTES = %w[title description kind status starts_at ends_at actual_started_at actual_ended_at all_day calendar_label blocks_calendar location_name location_address online_url pricing_type hourly_rate total_price contribution_type metadata genera_impresa].freeze

  class << self
    def payload_for(records)
      {
        "schema" => SCHEMA,
        "exported_at" => Time.current.iso8601,
        "commitments" => records.map { |record| serialize(record) }
      }
    end

    def serialize(record)
      record.attributes.slice("sync_key", *ATTRIBUTES, "calendar_key").merge(
        "domain_hostname" => record.domain.hostname,
        "profile_username" => record.profile.username,
        "created_by_username" => record.created_by_profile.username,
        "assignee_username" => record.assignee_profile&.username,
        "responsible_username" => record.responsible_profile&.username
      )
    end

    def valid_payload?(payload)
      payload.is_a?(Hash) && payload["schema"] == SCHEMA && Array(payload["commitments"]).all? { |item| item.is_a?(Hash) && item["sync_key"].present? && item["profile_username"].present? }
    end

    def fingerprint(payload)
      Digest::SHA256.hexdigest(JSON.generate(payload.deep_stringify_keys))
    end

    def summary(records)
      keys = records.map { |record| record["sync_key"] }
      existing = Brands::Impegno::Commitment.where(sync_key: keys).count
      { "total" => records.size, "new" => records.size - existing, "updates" => existing }
    end

    def apply!(import)
      records = Array(import.payload["commitments"])
      target = import.target_profile
      raise KeyError, "il file contiene impegni di un altro profilo" if target.present? && records.any? { |attributes| attributes["profile_username"] != target.username }

      records.each do |attributes|
        commitment = Brands::Impegno::Commitment.find_or_initialize_by(sync_key: attributes.fetch("sync_key"))
        record_profile = target || Profile.find_by!(username: attributes.fetch("profile_username"))
        assign(commitment, attributes, record_profile)
        commitment.save!
      end
      records.size
    end

    private

      def assign(record, attributes, target)
        record.assign_attributes(attributes.slice(*ATTRIBUTES))
        record.profile = target
        record.calendar_key = attributes["calendar_key"].to_s.start_with?("profile:") ? "profile:#{target.id}" : attributes["calendar_key"]
        record.domain = Domain.find_by!(hostname: attributes.fetch("domain_hostname"))
        record.created_by_profile = Profile.find_by(username: attributes["created_by_username"]) || target
        record.assignee_profile = Profile.find_by(username: attributes["assignee_username"])
        record.responsible_profile = Profile.find_by(username: attributes["responsible_username"])
      end
  end
end
