module Brands
  module Impegno
    class Contact < ApplicationRecord
      self.table_name = "impegno_contacts"

      def self.model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "ImpegnoContact")
      end

      KINDS = %w[person organization].freeze

      belongs_to :profile

      validates :name, presence: true
      validates :kind, inclusion: { in: KINDS }
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
    end
  end
end
