module Brands
  module Posturacorretta
    class TerritorialPath < ApplicationRecord
      self.table_name = "posturacorretta_territorial_paths"

      belongs_to :domain
      belongs_to :responsible_person, class_name: "Brands::Posturacorretta::DirectoryPerson"
      belongs_to :place, class_name: "Brands::Posturacorretta::DirectoryPlace", optional: true
      has_many :participants, class_name: "Brands::Posturacorretta::TerritorialPathParticipant", dependent: :destroy
      has_many :people, through: :participants, source: :person

      validates :title, :slug, presence: true
      validates :slug, uniqueness: { scope: :domain_id }
      validates :status, inclusion: { in: %w[draft available paused closed] }
    end
  end
end
