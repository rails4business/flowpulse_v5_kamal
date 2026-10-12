namespace :performance do
  desc "Validate PageSpeed budgets and list pending external measurements"
  task audit: :environment do
    result = Performance::DomainBudgetCatalog.new.validate

    puts "PageSpeed contract: #{result.valid? ? 'valid' : 'invalid'}"
    puts "Domains: #{result.document.fetch('domains', {}).size}"
    result.warnings.each { |warning| puts "WARN  #{warning}" }
    result.errors.each { |error| puts "ERROR #{error}" }

    abort "PageSpeed contract is invalid." unless result.valid?
  end
end
