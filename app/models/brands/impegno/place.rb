module Brands
  module Impegno
    class Place < ApplicationRecord
      self.table_name = "impegno_places"

      def self.model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "ImpegnoPlace")
      end

      KINDS = %w[home studio center event_space outdoor online other].freeze

      belongs_to :profile

      validates :name, presence: true
      validates :kind, inclusion: { in: KINDS }
      validates :online_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
    end
  end
end
