module Brands
  module Posturacorretta
    class DirectoryPerson < ApplicationRecord
      self.table_name = "posturacorretta_directory_people"

      belongs_to :domain
      belongs_to :profile, optional: true
      has_many :territorial_path_participants, class_name: "Brands::Posturacorretta::TerritorialPathParticipant", foreign_key: :person_id, dependent: :destroy
      has_many :territorial_paths, through: :territorial_path_participants
      has_many :responsible_territorial_paths, class_name: "Brands::Posturacorretta::TerritorialPath", foreign_key: :responsible_person_id, dependent: :restrict_with_exception

      validates :name, :slug, presence: true
      validates :slug, uniqueness: { scope: :domain_id }
      validates :visibility, inclusion: { in: %w[draft public] }
    end
  end
end
