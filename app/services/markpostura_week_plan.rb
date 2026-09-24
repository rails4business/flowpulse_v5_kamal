class MarkposturaWeekPlan
  CONFIG_PATH = Rails.root.join("config/data/sites/markpostura_it/shared/week_plan.yml").freeze
  WEEKS_PATH = Rails.root.join("config/data/markpostura/settimane").freeze
  GROUP_LESSONS_PATH = Rails.root.join("config/data/posturacorretta/programmi/calendario_lezioni_gruppo.yml").freeze
  DAY_NAMES = %w[Lunedì Martedì Mercoledì Giovedì Venerdì Sabato Domenica].freeze

  class << self
    def load(include_private: false)
      configuration = YAML.safe_load_file(CONFIG_PATH, permitted_classes: [], aliases: false) || {}
      week_plan = configuration.fetch("week_plan")
      week_plan["weeks"] = load_weeks(week_plan.fetch("spaces"), include_private: include_private)
      unless include_private
        week_plan.delete("private_reminders")
        week_plan.delete("private_program")
      end
      { "week_plan" => week_plan }
    end

    def week_source(week_key)
      return unless week_key.to_s.match?(/\A\d{4}-W\d{2}\z/)

      path = WEEKS_PATH.join("#{week_key}.yml")
      return unless path.file?

      { path: path, content: path.read }
    end

    private

    def load_weeks(spaces, include_private: false)
      allowed_spaces = spaces.map { |space| space.fetch("slug") }

      static_weeks = Dir.glob(WEEKS_PATH.join("*.yml")).sort.to_h do |path|
        week = YAML.safe_load_file(path, permitted_classes: [], aliases: false) || {}
        week["entries"] = Array(week["entries"]).reject { |entry| entry["visibility"] == "private" } unless include_private
        key = week.fetch("week")
        Array(week["entries"]).each do |entry|
          next if allowed_spaces.include?(entry["space"])

          raise ArgumentError, "Spazio Week Plan non valido: #{entry['space']} in #{path}"
        end
        [key, week]
      end
      weeks = static_weeks.merge(group_lesson_weeks(include_private: include_private))
      merge_database_sessions!(weeks, allowed_spaces, include_private: include_private)
      weeks
    end

    def merge_database_sessions!(weeks, allowed_spaces, include_private:)
      professional = Node.find_by(slug: "markpostura", professional: true)
      return unless professional

      sessions = DataSession.includes(:professional_calendar)
        .joins(:professional_calendar)
        .where(professional_calendars: { professional_node_id: professional.id, active: true })
        .where.not(starts_at: nil)
      sessions = sessions.where(visibility: "public") unless include_private

      sessions.find_each do |data_session|
        calendar = data_session.professional_calendar
        next unless calendar && allowed_spaces.include?(calendar.slug)

        starts_at = data_session.starts_at.in_time_zone
        ends_at = (data_session.ends_at || data_session.starts_at + 1.hour).in_time_zone
        monday = starts_at.to_date.beginning_of_week
        week_key = format("%<year>d-W%<week>02d", year: monday.cwyear, week: monday.cweek)
        week = weeks[week_key] ||= { "week" => week_key, "starts_on" => monday.iso8601, "entries" => [] }
        entry = {
          "day" => DAY_NAMES.fetch(starts_at.to_date.cwday - 1),
          "start" => starts_at.strftime("%H:%M"),
          "end" => ends_at.strftime("%H:%M"),
          "space" => calendar.slug,
          "title" => data_session.title,
          "location" => "Da definire",
          "source" => "database",
          "data_session_id" => data_session.id
        }
        week["entries"] << entry unless week.fetch("entries").any? { |existing| existing["data_session_id"] == data_session.id }
      end
    end

    def group_lesson_weeks(include_private:)
      calendar = YAML.safe_load_file(GROUP_LESSONS_PATH, permitted_classes: [], aliases: false).fetch("calendar")
      first_monday = Date.iso8601(calendar.fetch("starts_on"))
      lessons = calendar["group_lessons"] || [calendar.fetch("group_lesson")]

      calendar.fetch("courses").each_with_index.to_h do |course, index|
        monday = first_monday + index.weeks
        week_key = format("%<year>d-W%<week>02d", year: monday.cwyear, week: monday.cweek)
        entries = [
          {
            "day" => "Lunedì", "start" => calendar.fetch("publication_time"), "end" => "09:30",
            "space" => "postura-gruppo", "title" => "Pubblicazione corso · #{course.fetch('title')}",
            "location" => "Online", "related_course" => course.fetch("content_id")
          }
        ]
        entries.concat(lessons.map do |lesson|
          {
            "day" => lesson.fetch("day"), "start" => lesson.fetch("start"), "end" => lesson.fetch("end"),
            "space" => "postura-gruppo", "title" => "Lezione di gruppo · #{course.fetch('title')}",
            "location" => lesson.fetch("location"), "related_course" => course.fetch("content_id")
          }
        end)
        if include_private
          preparation = calendar.fetch("preparation")
          entries << {
            "day" => preparation.fetch("day"), "start" => preparation.fetch("start"), "end" => preparation.fetch("end"),
            "space" => "rails-processi", "title" => "Correzione e pubblicazione · #{course.fetch('title')}",
            "location" => "Studio", "visibility" => "private"
          }
        end
        youtube_live = calendar.fetch("youtube_live", {})
        if youtube_live["day"].present? && youtube_live["start"].present? && youtube_live["end"].present?
          entries << {
            "day" => youtube_live.fetch("day"), "start" => youtube_live.fetch("start"), "end" => youtube_live.fetch("end"),
            "space" => "postura-gruppo", "title" => "Diretta YouTube · #{course.fetch('title')}",
            "location" => youtube_live.fetch("location", "YouTube · Mark Postura"), "related_course" => course.fetch("content_id")
          }
        end
        [week_key, { "week" => week_key, "starts_on" => monday.iso8601, "entries" => entries }]
      end
    end
  end
end
