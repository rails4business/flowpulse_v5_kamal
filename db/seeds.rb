# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Domain.import_from_config! if defined?(Domain)

if defined?(Brands::Posturacorretta::DirectoryPerson)
  posturacorretta_domain = Domain.find_by(hostname: "posturacorretta.org")

  if posturacorretta_domain
    damiata = Brands::Posturacorretta::DirectoryPerson.find_or_initialize_by(domain: posturacorretta_domain, slug: "giovanni-damiata")
    damiata.assign_attributes(
      name: "Giovanni Damiata",
      role: "Medico M.G. · Fitoterapia europea",
      city: "Brescia",
      summary: "Propone percorsi professionali in presenza, da definire nei dettagli con sede, modalità di accesso e informazioni utili.",
      visibility: "public",
      listing_sections: %w[percorso contenuti],
      metadata: { "content_creator_key" => "damiata" }
    )
    damiata.save!

  end
end
