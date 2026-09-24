namespace :professional_calendars do
  desc "Validate configured professional calendars without saving"
  task validate: :environment do
    result = ProfessionalCalendarCatalog.from_config.import!(dry_run: true)
    puts "Valid professional calendar catalog: #{result.calendars} calendars."
  end

  desc "Import configured professional calendars into the database"
  task import: :environment do
    result = ProfessionalCalendarCatalog.from_config.import!
    puts "Imported #{result.calendars} professional calendars."
  end
end
