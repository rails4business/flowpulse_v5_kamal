module Brands
  module Posturacorretta
    class DirectoryPerson < ApplicationRecord
      self.table_name = "posturacorretta_directory_people"

      belongs_to :domain
      belongs_to :profile, optional: true


      validates :name, :slug, presence: true
      validates :slug, uniqueness: { scope: :domain_id }
      validates :visibility, inclusion: { in: %w[draft public] }
    end
  end
end
