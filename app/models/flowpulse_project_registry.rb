class FlowpulseProjectRegistry
  PATH = Rails.root.join("config/data/flowpulse/projects.yml")

  def self.load
    data = YAML.safe_load_file(PATH, permitted_classes: [], aliases: false) || {}
    registry = data.fetch("registry", {})
    projects = data.fetch("projects", [])
    active_projects = projects.select { |project| project["status"] == "active_pilot" }

    raise "Il registro Flowpulse deve avere un solo progetto pilota attivo" unless active_projects.one?
    raise "Il pilota attivo non corrisponde al registro Flowpulse" unless active_projects.first["slug"] == registry["active_pilot"]

    data
  end

  def self.active_project
    data = load
    data.fetch("projects").find { |project| project["slug"] == data.dig("registry", "active_pilot") }
  end
end
