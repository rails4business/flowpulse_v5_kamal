namespace :brand_requests do
  # Prova:   bin/rails brand_requests:link_profiles
  # Applica: APPLY=1 bin/rails brand_requests:link_profiles
  # In produzione (kamal app exec non usa una shell): bin/kamal app exec "env APPLY=1 bin/rails brand_requests:link_profiles"
  desc "Collega al profilo le richieste senza profilo (invito accettato o email affidabile)"
  task link_profiles: :environment do
    apply = ENV["APPLY"] == "1"
    linker = BrandRequestProfileLinker.new.call(apply:)
    describe = lambda do |match|
      request = match.brand_request
      "##{request.id} #{request.domain.hostname} · #{request.kind}/#{request.status} · #{request.participant_contact&.email} → @#{match.profile.username.presence || match.profile.display_name}"
    end

    puts(apply ? "APPLICATO" : "PROVA (nessuna modifica; per applicare: APPLY=1)")
    puts "\nDa collegare: #{linker.linked.size}"
    linker.linked.each { |match| puts "  #{describe.call(match)} (#{match.reason})" }
    puts "\nDa controllare a mano (email uguale a un utente non verificato): #{linker.to_review.size}"
    linker.to_review.each { |match| puts "  #{describe.call(match)}" }
  end
end
