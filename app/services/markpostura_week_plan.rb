class MarkposturaWeekPlan
  CONFIG_PATH = Rails.root.join("config/data/sites/markpostura_it/shared/week_plan.yml").freeze
  WEEKS_PATH = Rails.root.join("config/data/markpostura/settimane").freeze

  class << self
    def load
      configuration = YAML.safe_load_file(CONFIG_PATH, permitted_classes: [], aliases: false) || {}
      week_plan = configuration.fetch("week_plan")
      week_plan["weeks"] = load_weeks(week_plan.fetch("spaces"))
      { "week_plan" => week_plan }
    end

    def week_source(week_key)
      return unless week_key.to_s.match?(/\A\d{4}-W\d{2}\z/)

      path = WEEKS_PATH.join("#{week_key}.yml")
      return unless path.file?

      { path: path, content: path.read }
    end

    private

    def load_weeks(spaces)
      allowed_spaces = spaces.map { |space| space.fetch("slug") }

      Dir.glob(WEEKS_PATH.join("*.yml")).sort.to_h do |path|
        week = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
        key = week.fetch("week")
        Array(week["entries"]).each do |entry|
          next if allowed_spaces.include?(entry["space"])

          raise ArgumentError, "Spazio Week Plan non valido: #{entry['space']} in #{path}"
        end
        [key, week]
      end
    end
  end
end
