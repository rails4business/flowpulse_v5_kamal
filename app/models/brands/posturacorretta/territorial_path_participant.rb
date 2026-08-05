module Brands
  module Posturacorretta
    class TerritorialPathParticipant < ApplicationRecord
      self.table_name = "posturacorretta_territorial_path_participants"

      belongs_to :territorial_path, class_name: "Brands::Posturacorretta::TerritorialPath"
      belongs_to :person, class_name: "Brands::Posturacorretta::DirectoryPerson"

      validates :role, presence: true
    end
  end
end
