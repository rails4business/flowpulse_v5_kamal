class SkillProductSnapshot
  VERSION = 1
  ATTRIBUTES = %w[title status visibility format data source_path published_at].freeze

  def self.for_owner(username, path: nil)
    profile = Profile.find_by!(username: username.to_s)
    new(owner_profile: profile, path:)
  end

  def initialize(owner_profile:, path: nil, repository_root: Rails.root)
    @owner_profile = owner_profile
    @path = Pathname(path || Rails.root.join("config/data/rails4b/skill_products.yml"))
    @repository_root = Pathname(repository_root)
  end

  attr_reader :owner_profile, :path

  def export!
    path.dirname.mkpath
    products = owned_products
    products.each { |product| export_body!(product) if product.source_path.present? }
    path.write(YAML.dump(document(products:)))
    path
  end

  def import!(dry_run: false)
    payload = load_payload
    definitions = payload.fetch("products").to_h.deep_stringify_keys
    validate_definitions!(definitions)
    imported = 0

    ActiveRecord::Base.transaction do
      definitions.each do |key, attributes|
        skill = owner_profile.reusable_skills.find_by!(slug: attributes.fetch("skill_slug"))
        node = Node.find_by!(slug: attributes.fetch("node_slug"))
        activation = skill.reusable_skill_nodes.find_or_create_by!(node:) do |record|
          record.status = "draft"
          record.activated_by_profile = owner_profile
        end
        product = activation.skill_products.find_or_initialize_by(slug: attributes.fetch("slug"))
        product.assign_attributes(attributes.slice(*ATTRIBUTES))
        product.created_by_profile ||= owner_profile
        product.body = imported_body(attributes)
        product.save!
        imported += 1
      rescue ActiveRecord::RecordInvalid => error
        raise ArgumentError, "Prodotto #{key}: #{error.record.errors.full_messages.to_sentence}"
      end

      raise ActiveRecord::Rollback if dry_run
    end

    imported
  end

  def document(products: owned_products, include_bodies: false)
    {
      "version" => VERSION,
      "owner_username" => owner_profile.username,
      "products" => products.index_with { |product| serialized_product(product, include_body: include_bodies) }
        .transform_keys { |product| product_key(product) }
    }
  end

  private

    def owned_products
      SkillProduct
        .joins(reusable_skill_node: :reusable_skill)
        .where(reusable_skills: { owner_profile_id: owner_profile.id })
        .includes(reusable_skill_node: %i[reusable_skill node])
        .order(:id)
    end

    def load_payload
      raise ArgumentError, "Catalogo prodotti mancante: #{relative_path}" unless path.file?

      payload = YAML.safe_load_file(path, permitted_classes: [], aliases: false).to_h.deep_stringify_keys
      raise ArgumentError, "Versione catalogo prodotti non supportata" unless payload.fetch("version") == VERSION
      unless payload.fetch("owner_username") == owner_profile.username
        raise ArgumentError, "Catalogo prodotti destinato a un altro proprietario"
      end
      payload
    end

    def validate_definitions!(definitions)
      definitions.each do |key, attributes|
        %w[slug skill_slug node_slug title].each do |attribute|
          raise ArgumentError, "Prodotto #{key}: #{attribute} mancante" if attributes[attribute].blank?
        end
        owner_profile.reusable_skills.find_by!(slug: attributes["skill_slug"])
        Node.find_by!(slug: attributes["node_slug"])
        validate_source_path!(attributes["source_path"]) if attributes["source_path"].present?
      end
    end

    def serialized_product(product, include_body: false)
      activation = product.reusable_skill_node
      attributes = ATTRIBUTES.index_with { |attribute| product.public_send(attribute).presence }.compact
      attributes["published_at"] = product.published_at.iso8601 if product.published_at.present?
      attributes.merge!(
        "slug" => product.slug,
        "skill_slug" => activation.reusable_skill.slug,
        "node_slug" => activation.node.slug
      )
      attributes["body"] = product.body if product.body.present? && (product.source_path.blank? || include_body)
      attributes
    end

    def imported_body(attributes)
      source_path = attributes["source_path"].presence
      return attributes["body"] if source_path.blank?

      full_path = repository_path(source_path)
      return full_path.read if full_path.file?
      return attributes["body"] if attributes["body"].present?

      raise ArgumentError, "File prodotto mancante: #{source_path}"
    end

    def export_body!(product)
      full_path = repository_path(product.source_path)
      full_path.dirname.mkpath
      full_path.write(product.body.to_s)
    end

    def repository_path(source_path)
      validate_source_path!(source_path)
      @repository_root.join(source_path).cleanpath
    end

    def validate_source_path!(source_path)
      pathname = Pathname(source_path.to_s)
      unless source_path.to_s.start_with?("config/data/") && !pathname.absolute? && !pathname.each_filename.include?("..")
        raise ArgumentError, "Percorso prodotto non sicuro: #{source_path}"
      end
    end

    def product_key(product)
      activation = product.reusable_skill_node
      [activation.reusable_skill.slug, activation.node.slug, product.slug].join("--")
    end

    def relative_path
      path.relative_path_from(Rails.root)
    rescue ArgumentError
      path
    end
end
