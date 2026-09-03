namespace :data_events do
  desc "Crea o aggiorna i quattro orari PosturaCorretta per una settimana (WEEK_START=YYYY-MM-DD)"
  task seed_posturacorretta_week: :environment do
    week_start = Date.iso8601(ENV.fetch("WEEK_START", Date.current.next_week(:monday).iso8601))
    result = DataEvents::PosturaCorrettaWeeklySchedule.new(week_start: week_start).call

    puts "Corso: #{result.fetch(:course).title}"
    result.fetch(:sessions).each do |session|
      puts "- #{I18n.l(session.starts_at, format: :long)}–#{session.ends_at.strftime('%H:%M')} · #{session.title}"
    end
  end
end

namespace :data_events do
  desc "Importa in modo idempotente gli eventi YAML di un dominio (DOMAIN=posturacorretta)"
  task import_yaml_events: :environment do
    domain_key = ENV.fetch("DOMAIN", "posturacorretta")
    result = DataEvents::YamlEventImporter.new(domain_key: domain_key).call

    puts "Importati #{result.fetch(:events).size} eventi e #{result.fetch(:places).size} luoghi da #{domain_key}."
  end
end
