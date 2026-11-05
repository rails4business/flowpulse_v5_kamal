# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.precompile += %w[brand_admin.css]

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Lexxy 0.9 ships its compiled Propshaft assets under app/assets. Register
# those directories explicitly because this application boots Propshaft before
# the engine-provided paths are consistently available in development.
lexxy_root = Gem.loaded_specs.fetch("lexxy").full_gem_path
Rails.application.config.assets.paths << File.join(lexxy_root, "app/assets/stylesheets")
Rails.application.config.assets.paths << File.join(lexxy_root, "app/assets/javascript")
