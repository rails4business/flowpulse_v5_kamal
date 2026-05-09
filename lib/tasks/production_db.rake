namespace :production_db do
  desc "Create and migrate all production databases explicitly (primary, cache, queue, cable)"
  task setup_all: :environment do
    unless Rails.env.production?
      abort "production_db:setup_all must run with RAILS_ENV=production"
    end

    db_tasks = ActiveRecord::Tasks::DatabaseTasks
    db_configs = ActiveRecord::Base.configurations.configs_for(env_name: "production")

    db_configs.each do |db_config|
      puts "\n==> Creating #{db_config.name} database (#{db_config.database})"
      db_tasks.create(db_config)
    end

    db_configs.each do |db_config|
      puts "\n==> Migrating #{db_config.name} database (#{db_config.database})"
      db_tasks.send(:with_temporary_pool, db_config) do
        db_tasks.migrate(skip_initialize: true)
      end
    end
  end
end
