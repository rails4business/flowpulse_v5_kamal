require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FlowpulseV5
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    config.time_zone = "Europe/Rome"
    config.active_record.default_timezone = :utc

    # Keep Lexxy opt-in: only forms using `lexxy_rich_text_area` get the editor.
    config.lexxy.override_action_text_defaults = false

    # Lexxy 0.9.x registers `app/javascript`, while its compiled module lives
    # under `app/assets/javascript`. Add the real path for Propshaft/importmap.
    lexxy_gem_path = Gem.loaded_specs.fetch("lexxy").full_gem_path
    config.assets.paths << "#{lexxy_gem_path}/app/assets/javascript"
    config.assets.paths << "#{lexxy_gem_path}/app/assets/stylesheets"

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
