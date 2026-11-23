# Due gruppi di test:
#   bin/rails test:indispensabili  → tutto tranne i file lenti qui sotto e i test di sistema (gira in CI)
#   bin/rails test:contenuti       → solo i file lenti, da lanciare a mano quando cambiano cataloghi e pagine
# I file "contenuti" reimportano a ogni test i cataloghi YAML (corsi, contenuti, node, linee, metro map).
TEST_SUITE_CONTENTS_FILES = %w[
  test/controllers/posturacorretta_contents_controller_test.rb
  test/controllers/landing_contents_controller_test.rb
  test/controllers/nodes_controller_test.rb
  test/controllers/landing_controller_test.rb
  test/controllers/posturacorretta_controller_test.rb
  test/controllers/posturacorretta/learning_controller_test.rb
  test/services/domain_content_catalog_test.rb
  test/services/line_offer_catalog_test.rb
  test/services/node_catalog_entry_writer_test.rb
  test/services/metro_map_catalog_test.rb
  test/services/node_catalog_test.rb
  test/services/posturacorretta/content_repository_test.rb
  test/services/posturacorretta/landing_line_test.rb
].freeze

namespace :test do
  desc "Test indispensabili (CI): tutti tranne i test lenti di contenuti/cataloghi e i test di sistema"
  task indispensabili: :environment do
    files = Dir["test/**/*_test.rb"].sort - Dir["test/system/**/*_test.rb"] - TEST_SUITE_CONTENTS_FILES
    Rails::TestUnit::Runner.run_from_rake("test", files)
  end

  desc "Test lenti di contenuti e cataloghi (a mano)"
  task contenuti: :environment do
    missing = TEST_SUITE_CONTENTS_FILES.reject { |file| File.exist?(file) }
    abort "File di test mancanti in lib/tasks/test_suites.rake: #{missing.join(', ')}" if missing.any?

    Rails::TestUnit::Runner.run_from_rake("test", TEST_SUITE_CONTENTS_FILES)
  end
end
