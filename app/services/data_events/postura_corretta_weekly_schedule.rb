module DataEvents
  class PosturaCorrettaWeeklySchedule
    DEFAULT_TIMES = [
      [2, "15:00", "16:00"],
      [2, "20:00", "21:00"],
      [4, "15:00", "16:00"],
      [4, "20:00", "21:00"]
    ].freeze

    attr_reader :week_start, :lesson_title, :domain, :teacher, :place

    def initialize(week_start:, lesson_title: "Lezione pratica PosturaCorretta in un mese",
                   domain: nil, teacher: nil, place: nil)
      @week_start = week_start.to_date.beginning_of_week(:monday)
      @lesson_title = lesson_title
      @domain = domain || Domain.find_by!(hostname: "posturacorretta.org")
      @teacher = teacher || Profile.find_by!(username: "markpostura")
      @place = place || find_or_create_place
    end

    def call
      DataEvent.transaction do
        course = find_or_create_course
        service = find_or_create_service
        sessions = DEFAULT_TIMES.map do |day_number, start_time, end_time|
          date = week_start + (day_number - 1).days
          day = find_or_create_day(course, date)
          find_or_create_session(day, service, date, start_time, end_time)
        end

        { course: course, service: service, sessions: sessions }
      end
    end

    private

      def find_or_create_place
        Brands::Impegno::Place.find_or_create_by!(
          profile: teacher,
          domain: domain,
          name: "Sede PosturaCorretta · Viadana di Calvisano"
        ) do |record|
          record.kind = "center"
          record.scope = "domain"
          record.approval_status = "approved"
          record.notes = "Indirizzo completo da confermare."
        end
      end

      def find_or_create_course
        record = DataEvent.find_or_initialize_by(
          domain: domain,
          node_kind: "root",
          classification: "course",
          metadata: { "source_key" => "posturacorretta-in-un-mese-guided" }
        )
        record.assign_attributes(
          title: "PosturaCorretta in un mese · percorso guidato",
          description: "Programma guidato con una lezione settimanale proposta in quattro orari alternativi.",
          created_by_profile: teacher,
          responsible_profile: teacher,
          operator_roles: [{ "role" => "teacher", "profile_id" => teacher.id }],
          place: place,
          active_from: week_start,
          status: "organizing",
          visibility: "public",
          published_at: record.published_at || Time.current,
          registration_status: "open",
          registration_mode: "required",
          booking_mode: "session",
          recurrence: {
            "frequency" => "weekly",
            "timezone" => "Europe/Rome",
            "alternatives_same_lesson" => true,
            "weekly_lesson_changes" => true,
            "times" => DEFAULT_TIMES.map { |day, from, to| { "weekday" => day, "starts_at" => from, "ends_at" => to } }
          }
        )
        record.save!
        record
      end

      def find_or_create_service
        record = DataEvent.find_or_initialize_by(
          domain: domain,
          node_kind: "root",
          classification: "class",
          metadata: { "source_key" => "posturacorretta-group-lesson" }
        )
        record.assign_attributes(
          title: "Lezione di gruppo PosturaCorretta",
          description: "Servizio standard per una lezione di gruppo PosturaCorretta.",
          created_by_profile: teacher,
          responsible_profile: teacher,
          place: place,
          status: "confirmed",
          visibility: "private",
          service_definition: true,
          service_scope: "domain",
          duration_minutes: 60,
          minimum_participants: 1,
          allowed_roles: %w[student teacher_trainee],
          operator_roles: [{ "role" => "teacher", "profile_id" => teacher.id }],
          booking_mode: "session"
        )
        record.save!
        record
      end

      def find_or_create_day(course, date)
        record = DataEvent.find_or_initialize_by(
          parent: course,
          node_kind: "day",
          metadata: { "schedule_date" => date.iso8601 }
        )
        record.assign_attributes(
          title: I18n.l(date, format: "%A %-d %B %Y"),
          classification: course.classification,
          domain: domain,
          created_by_profile: teacher,
          starts_at: Time.zone.local(date.year, date.month, date.day),
          all_day: true,
          status: "proposed",
          visibility: "public",
          published_at: record.published_at || Time.current,
          registration_status: "open",
          registration_mode: "required",
          position: date.cwday
        )
        record.save!
        record
      end

      def find_or_create_session(day, service, date, start_time, end_time)
        starts_at = zoned_time(date, start_time)
        ends_at = zoned_time(date, end_time)
        source_key = "#{date.iso8601}-#{start_time.tr(':', '')}"
        record = DataEvent.find_or_initialize_by(
          parent: day,
          node_kind: "session",
          metadata: { "source_key" => source_key, "lesson_key" => "pratica-guidata-primo-mese" }
        )
        record.assign_attributes(
          title: lesson_title,
          classification: day.classification,
          domain: domain,
          created_by_profile: teacher,
          responsible_profile: teacher,
          place: place,
          service_data_event: service,
          starts_at: starts_at,
          ends_at: ends_at,
          position: starts_at.hour,
          status: "proposed",
          visibility: "public",
          published_at: record.published_at || Time.current,
          registration_status: "open",
          registration_mode: "required",
          bookable: true,
          booking_mode: "session",
          booking_notes: "Scegli uno dei quattro orari alternativi della settimana. L'appuntamento viene confermato con almeno un partecipante."
        )
        record.save!
        record
      end

      def zoned_time(date, value)
        hour, minute = value.split(":").map(&:to_i)
        Time.zone.local(date.year, date.month, date.day, hour, minute)
      end
  end
end
