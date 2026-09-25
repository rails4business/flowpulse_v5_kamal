class ProfessionalCalendarCatalog
  Result = Data.define(:calendars)

  def self.from_config(environment = Rails.env)
    new(Rails.application.config_for(:professional_calendars, env: environment))
  end

  def initialize(config)
    @definitions = config.to_h.deep_stringify_keys.fetch("calendars", {})
  end

  def validate!
    raise ArgumentError, "config/professional_calendars.yml non contiene calendars" if @definitions.empty?

    @definitions.each do |slug, attributes|
      raise ArgumentError, "Calendario #{slug}: context_node_slug mancante" if attributes["context_node_slug"].blank?
      raise ArgumentError, "Calendario #{slug}: professional_node_slug mancante" if attributes["professional_node_slug"].blank?
      raise ArgumentError, "Calendario #{slug}: title mancante" if attributes["title"].blank?
      raise ArgumentError, "Calendario #{slug}: colore non valido" unless ProfessionalCalendar::COLORS.include?(attributes.fetch("color", "slate"))
    end
    true
  end

  def import!(dry_run: false)
    validate!

    ActiveRecord::Base.transaction do
      @definitions.each do |slug, attributes|
        context_node = Node.find_by!(slug: attributes.fetch("context_node_slug"))
        professional_node = Node.professional.find_by!(slug: attributes.fetch("professional_node_slug"))
        calendar = ProfessionalCalendar.find_or_initialize_by(slug: slug)
        calendar.assign_attributes(
          context_node: context_node,
          professional_node: professional_node,
          created_by_user: professional_node.role_assignment.user,
          title: attributes.fetch("title"),
          short_label: attributes["short_label"],
          description: attributes["description"],
          color: attributes.fetch("color", "slate"),
          active: true
        )
        calendar.save!
      end
      raise ActiveRecord::Rollback if dry_run
    end

    Result.new(calendars: @definitions.size)
  end
end
