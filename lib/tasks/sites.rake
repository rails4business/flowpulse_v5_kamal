namespace :sites do
  desc "Validate editorial Sites, mounts, pages and registered components"
  task validate: :environment do
    result = Editorial::Validator.new.validate

    result.errors.each { |message| warn "ERROR: #{message}" }
    result.warnings.each { |message| warn "WARNING: #{message}" }

    puts "Sites: #{result.counts.fetch(:sites)}"
    puts "Pages: #{result.counts.fetch(:pages)}"
    puts "Mounts: #{result.counts.fetch(:mounts)}"
    puts "Errors: #{result.errors.length}"
    puts "Warnings: #{result.warnings.length}"

    strict_failure = ENV["STRICT"] == "1" && result.warnings.any?
    abort "Editorial Sites validation failed" if result.errors.any? || strict_failure
  end
end
