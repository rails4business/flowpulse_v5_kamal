module Brands
  module Posturacorretta
    class DirectoryPlace < ApplicationRecord
      self.table_name = "posturacorretta_directory_places"

      belongs_to :domain


      validates :name, :slug, presence: true
      validates :slug, uniqueness: { scope: :domain_id }
      validates :visibility, inclusion: { in: %w[draft public] }
    end
  end
end
