class ReusableSkillSnapshot
  VERSION = 1
  SLUG_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  ATTRIBUTES = %w[
    title category status description purpose operation_notes reuse_notes
    resource_type documentation_markdown
  ].freeze

  def self.for_owner(username, path: nil)
    profile = Profile.find_by!(username: username.to_s)
    new(owner_profile: profile, path:)
  end

  def initialize(owner_profile:, path: nil)
    @owner_profile = owner_profile
    @path = Pathname(path || Rails.root.join("config/data/rails4b/skills.yml"))
  end

  attr_reader :owner_profile, :path

  def export!
    path.dirname.mkpath
    path.write(YAML.dump(document))
    path
  end

  def import!(dry_run: false)
    payload = load_payload
    definitions = payload.fetch("skills").to_h.deep_stringify_keys
    validate_definitions!(definitions)
    imported = {}

    ActiveRecord::Base.transaction do
      definitions.each do |slug, attributes|
        skill = owner_profile.reusable_skills.find_or_initialize_by(slug:)
        skill.assign_attributes(attributes.slice(*ATTRIBUTES))
        skill.save!
        imported[slug] = skill
      end

      definitions.each do |slug, attributes|
        import_dependencies!(imported.fetch(slug), attributes, imported)
        import_activations!(imported.fetch(slug), attributes)
      end

      raise ActiveRecord::Rollback if dry_run
    end

    imported.size
  end

  def document
    skills = owner_profile.reusable_skills
      .includes(:required_skills, reusable_skill_nodes: :node)
      .order(:slug)

    {
      "version" => VERSION,
      "owner_username" => owner_profile.username,
      "skills" => skills.index_with { |skill| serialized_skill(skill) }.transform_keys(&:slug)
    }
  end

  private

    def load_payload
      raise ArgumentError, "Catalogo Skill mancante: #{relative_path}" unless path.file?

      payload = YAML.safe_load_file(path, permitted_classes: [], aliases: false).to_h.deep_stringify_keys
      raise ArgumentError, "Versione catalogo Skill non supportata" unless payload.fetch("version") == VERSION
      unless payload.fetch("owner_username") == owner_profile.username
        raise ArgumentError, "Catalogo destinato a un altro proprietario"
      end

      payload
    end

    def validate_definitions!(definitions)
      raise ArgumentError, "Il catalogo non contiene Skill" if definitions.empty?

      definitions.each do |slug, attributes|
        raise ArgumentError, "Slug Skill non valido: #{slug}" unless slug.match?(SLUG_PATTERN)
        raise ArgumentError, "Skill #{slug}: title mancante" if attributes["title"].blank?

        Array(attributes["requires"]).each do |required_slug|
          next if definitions.key?(required_slug) || owner_profile.reusable_skills.exists?(slug: required_slug)

          raise ArgumentError, "Skill #{slug}: dipendenza sconosciuta #{required_slug}"
        end

        Array(attributes["nodes"]).each do |activation|
          activation = activation.to_h.deep_stringify_keys
          raise ArgumentError, "Skill #{slug}: Node sconosciuto #{activation['slug']}" unless Node.exists?(slug: activation["slug"])
        end
      end
    end

    def import_dependencies!(skill, attributes, imported)
      Array(attributes["requires"]).each do |required_slug|
        required_skill = imported[required_slug] || owner_profile.reusable_skills.find_by!(slug: required_slug)
        skill.reusable_skill_dependencies.find_or_create_by!(required_skill:) do |dependency|
          dependency.dependency_kind = "uses"
        end
      end
    end

    def import_activations!(skill, attributes)
      Array(attributes["nodes"]).each do |activation_attributes|
        activation_attributes = activation_attributes.to_h.deep_stringify_keys
        node = Node.find_by!(slug: activation_attributes.fetch("slug"))
        activation = skill.reusable_skill_nodes.find_or_initialize_by(node:)
        activation.status = activation_attributes["status"].presence || "draft"
        activation.configuration = activation_attributes["configuration"].to_h
        activation.activated_by_profile ||= owner_profile
        activation.save!
      end
    end

    def serialized_skill(skill)
      attributes = ATTRIBUTES.index_with { |attribute| skill.public_send(attribute).presence }.compact
      attributes["requires"] = skill.required_skills.order(:slug).pluck(:slug) if skill.required_skills.any?
      if skill.reusable_skill_nodes.any?
        attributes["nodes"] = skill.reusable_skill_nodes.sort_by { |activation| activation.node.slug }.map do |activation|
          {
            "slug" => activation.node.slug,
            "status" => activation.status,
            "configuration" => activation.configuration.presence
          }.compact
        end
      end
      attributes
    end

    def relative_path
      path.relative_path_from(Rails.root)
    rescue ArgumentError
      path
    end
end
