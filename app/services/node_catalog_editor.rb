class NodeCatalogEditor
  def self.enabled?
    return false if Rails.env.production?

    ActiveModel::Type::Boolean.new.cast(ENV.fetch("NODE_CATALOG_EDITOR_ENABLED", "true"))
  end
end
