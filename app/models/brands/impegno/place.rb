module Brands
  module Impegno
    class Place < ApplicationRecord
      self.table_name = "impegno_places"

      def self.model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "ImpegnoPlace")
      end

      KINDS = %w[home studio center event_space outdoor online other].freeze
      SCOPES = %w[private domain brand].freeze
      APPROVAL_STATUSES = %w[draft pending approved rejected archived].freeze

      belongs_to :profile
      belongs_to :domain, optional: true

      validates :name, presence: true
      validates :kind, inclusion: { in: KINDS }
      validates :scope, inclusion: { in: SCOPES }
      validates :approval_status, inclusion: { in: APPROVAL_STATUSES }
      validates :online_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
    end
  end
end
