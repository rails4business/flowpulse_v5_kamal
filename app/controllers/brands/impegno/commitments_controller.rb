require "digest"

module Brands
  module Impegno
    class CommitmentsController < ApplicationController
      layout "landing"

  def index
    if params[:workspace] != "1"
      destination = {
        area: params[:area].presence || "user",
        view: params[:view].presence || "agenda",
        date: params[:date].presence
      }.compact
      return redirect_to impegno_path(destination)
    end

    @domains = available_domains

    # Area & View navigation
    @active_area = %w[agenda user professional places contacts].include?(params[:area]) ? params[:area] : "agenda"
    requested_view = params[:view] == "programs" ? "practices" : params[:view]
    @active_view = %w[agenda practices recurring value reports].include?(requested_view) ? requested_view : "agenda"
    @agenda_filter = @active_area == "agenda" && @active_view == "agenda" && Current.user.professional_user? ? params[:agenda_filter].presence_in(%w[all events booking_slots]) || "all" : nil
    
    # Il calendario è unico: il dominio è un contesto del commitment, non un calendario separato.
    @default_domain = default_domain_for(params[:default_brand])

    @profile = current_profile
    @commitments = @profile.data_commitments.includes(:domain).order(:starts_at)
    @agenda_date = parse_agenda_date
    if @agenda_date
      @commitments = @commitments.select do |commitment|
        (commitment.actual_started_at || commitment.starts_at)&.in_time_zone&.to_date == @agenda_date
      end
    elsif params[:period] == "upcoming"
      @commitments = @commitments.select { |commitment| (commitment.actual_started_at || commitment.starts_at) >= Time.current }
    elsif params[:period] == "past"
      @commitments = @commitments.select { |commitment| (commitment.actual_started_at || commitment.starts_at) < Time.current }
    end
    if @agenda_filter == "events"
      @commitments = @commitments.select { |commitment| commitment.kind == "event" }
    elsif @agenda_filter == "booking_slots"
      @commitments = @commitments.select { |commitment| ActiveModel::Type::Boolean.new.cast(commitment.metadata.to_h["booking_slot"]) }
    end
    
    # Raggruppa i commitment per giorno
    @commitments_by_day = @commitments.group_by { |c| (c.actual_started_at || c.starts_at || Time.current).to_date }
  end

  def create
    return create_personal_commitment unless params[:project_slug].present?

    return redirect_to(data_commitments_path, alert: "Solo il superadmin può registrare attività GeneraImpresa.") unless Current.user&.superadmin_user?

    project, step, task = find_genera_impresa_context!
    profile = current_profile
    domain = current_domain || Domain.find_for_host("posturacorretta.org")
    raise ActiveRecord::RecordNotFound, "Dominio PosturaCorretta non configurato" unless domain

    start_now = ActiveModel::Type::Boolean.new.cast(params[:start_now])
    if start_now && active_timer_for_calendar?(profile, "profile:#{profile.id}")
      return redirect_to activity_return_path(project, step, task), alert: "Hai già un’attività in corso. Concludila prima di iniziarne un’altra."
    end

    commitment = Commitment.new(start_now ? {} : data_commitment_params)
    commitment.profile = profile
    commitment.created_by_profile = profile
    commitment.domain = domain
    commitment.assignee_profile = profile
    commitment.calendar_key = "profile:#{profile.id}"
    commitment.calendar_label = profile.display_name.presence || profile.username
    commitment.kind = "work"
    if start_now
      activity_description = params.dig(:data_commitment, :description).to_s.strip
      return redirect_to(activity_return_path(project, step, task), alert: "Scrivi cosa stai per fare.") if activity_description.blank?

      commitment.title = task&.fetch("title") || "Attività dello step: #{step.fetch('title')}"
      commitment.description = activity_description
      commitment.starts_at = Time.current
      commitment.actual_started_at = Time.current
      commitment.status = "in_progress"
      requested_pricing = params.dig(:data_commitment, :pricing_type).to_s
      commitment.pricing_type = Commitment::PRICING_TYPES.include?(requested_pricing) ? requested_pricing : "none"
      commitment.hourly_rate = params.dig(:data_commitment, :hourly_rate) if commitment.pricing_type == "hourly"
      commitment.total_price = params.dig(:data_commitment, :total_price) if commitment.pricing_type == "fixed"
      commitment.contribution_type = "time_investment"
    else
      commitment.status = "completed"
    end
    commitment.genera_impresa = {
      "project_slug" => project.fetch("slug"),
      "phase_key" => "implementation",
      "step_key" => step.fetch("key"),
      "task_key" => task&.fetch("key")
    }.compact

    if commitment.save
      notice = start_now ? "Timer avviato." : "Attività registrata nel calendario."
      redirect_to activity_return_path(project, step, task), notice: notice
    else
      redirect_to activity_return_path(project, step, task), alert: commitment.errors.full_messages.to_sentence
    end
  end

  def update
    commitment = owned_commitment
    domain = available_domains.find_by(id: params.dig(:data_commitment, :domain_id))
    return redirect_to(data_commitments_path, alert: "Seleziona un dominio disponibile.") unless domain

    commitment.assign_attributes(personal_commitment_params)
    commitment.domain = domain
    assign_calendar_identity(commitment)
    if commitment.actual_started_at.present?
      commitment.status = commitment.actual_ended_at.present? ? "completed" : "in_progress"
    elsif %w[in_progress completed].include?(commitment.status)
      commitment.status = "planned"
    end
    commitment.metadata = commitment.metadata.to_h.merge(
      "context_label" => params.dig(:data_commitment, :context_label).to_s.strip.presence
    ).compact

    if commitment.save
      redirect_to commitment_return_path(commitment), notice: "Impegno aggiornato."
    else
      redirect_to commitment_return_path(commitment), alert: commitment.errors.full_messages.to_sentence
    end
  end

  def start
    commitment = owned_commitment
    unless %w[draft planned confirmed].include?(commitment.status) && commitment.actual_started_at.blank?
      return redirect_to commitment_return_path(commitment), alert: "Questo impegno non può essere avviato."
    end
    if active_timer_for_calendar?(current_profile, commitment.calendar_key, excluding: commitment)
      return redirect_to commitment_return_path(commitment), alert: "Questo calendario ha già un’attività in corso. Concludila prima di iniziarne un’altra."
    end

    commitment.update!(status: "in_progress", actual_started_at: Time.current, actual_ended_at: nil)
    redirect_to commitment_return_path(commitment), notice: "Attività iniziata."
  end

  def complete
    commitment = owned_commitment
    unless commitment.tracking?
      return redirect_to commitment_return_path(commitment), alert: "Avvia l’attività prima di concluderla."
    end

    pricing_type = params.dig(:data_commitment, :pricing_type).presence || commitment.pricing_type
    unless Commitment::PRICING_TYPES.include?(pricing_type)
      return redirect_to commitment_return_path(commitment), alert: "La modalità di valorizzazione non è valida."
    end

    commitment.pricing_type = pricing_type
    case pricing_type
    when "hourly"
      commitment.hourly_rate = params.dig(:data_commitment, :hourly_rate)
      commitment.total_price = nil
    when "fixed"
      commitment.hourly_rate = nil
      commitment.total_price = params.dig(:data_commitment, :total_price)
    else
      commitment.hourly_rate = nil
      commitment.total_price = nil
    end
    commitment.status = "completed"
    commitment.actual_ended_at = Time.current
    commitment.save!
    redirect_to commitment_return_path(commitment), notice: "Attività conclusa."
  end

  def complete_step
    return redirect_to(data_commitments_path, alert: "Solo il superadmin può concludere gli step GeneraImpresa.") unless Current.user&.superadmin_user?

    project, step = find_genera_impresa_step!
    note = params[:completion_note].to_s.strip
    return redirect_to(project_step_path(project, step), alert: "Specifica cosa è stato concluso o perché lo step viene chiuso senza attività.") if note.blank?

    profile = current_profile
    domain = current_domain || Domain.find_for_host("posturacorretta.org")
    raise ActiveRecord::RecordNotFound, "Dominio PosturaCorretta non configurato" unless domain

    marker_context = {
      "project_slug" => project.fetch("slug"),
      "phase_key" => "implementation",
      "step_key" => step.fetch("key"),
      "record_type" => "step_completion"
    }
    existing = profile.data_commitments.where(status: "completed").find { |item| item.genera_impresa.to_h.slice(*marker_context.keys) == marker_context }
    return redirect_to(project_step_path(project, step), notice: "Lo step risulta già concluso.") if existing

    missing_data = step_missing_data(step)
    profile.data_commitments.create!(
      profile: profile,
      created_by_profile: profile,
      domain: domain,
      title: "Step concluso: #{step.fetch('title')}",
      description: note,
      kind: "work",
      status: "completed",
      starts_at: Time.current,
      pricing_type: "none",
      contribution_type: "unpaid",
      blocks_calendar: false,
      genera_impresa: marker_context,
      metadata: { "missing_data_at_completion" => missing_data }
    )
    redirect_to project_step_path(project, step), notice: missing_data.any? ? "Step concluso. Sono indicati i dati ancora mancanti." : "Step concluso."
  end

  def destroy
    commitment = owned_commitment
    return_path = commitment_return_path(commitment)
    commitment.destroy!
    redirect_to return_path, notice: "Impegno eliminato."
  end

  private

    def parse_agenda_date
      return if params[:date].blank?

      Date.iso8601(params[:date])
    rescue Date::Error
      nil
    end

    def create_personal_commitment
      domain = available_domains.find_by(id: params.dig(:data_commitment, :domain_id))
      return redirect_to(data_commitments_path, alert: "Seleziona un dominio disponibile.") unless domain

      commitment = Commitment.new(personal_commitment_params)
      commitment.profile = current_profile
      commitment.created_by_profile = current_profile
      commitment.domain = domain
      assign_calendar_identity(commitment)
      start_now = ActiveModel::Type::Boolean.new.cast(params[:start_now])
      if start_now
        if active_timer_for_calendar?(current_profile, commitment.calendar_key)
          return redirect_to personal_commitment_return_path, alert: "Hai già un’attività in corso. Concludila prima di registrarne un’altra."
        end

        commitment.starts_at = Time.current
        commitment.actual_started_at = Time.current
        commitment.status = "in_progress"
      else
        commitment.status = "planned"
      end
      commitment.pricing_type = "none"
      commitment.contribution_type = "unpaid"
      commitment.metadata = { "context_label" => params.dig(:data_commitment, :context_label).to_s.strip.presence }.compact

      if commitment.save
        notice = start_now ? "Registrazione avviata." : "Impegno aggiunto al tuo elenco."
        redirect_to personal_commitment_return_path, notice: notice
      else
        redirect_to personal_commitment_return_path, alert: commitment.errors.full_messages.to_sentence
      end
    end

    def current_profile
      Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
    end

    def personal_commitment_return_path
      candidate = params[:return_to].to_s
      return candidate if candidate.start_with?("/") && !candidate.start_with?("//")

      impegno_path(area: "user", view: "agenda")
    end

    def owned_commitment
      current_profile.data_commitments.find(params[:id])
    end

    def assign_calendar_identity(commitment)
      requested_label = params.dig(:data_commitment, :calendar_label).to_s.strip
      own_labels = [current_profile.display_name, current_profile.username, "@#{current_profile.username}"].compact.map { |value| value.to_s.downcase.strip }

      if requested_label.blank? || own_labels.include?(requested_label.downcase)
        commitment.assignee_profile = current_profile
        commitment.calendar_key = "profile:#{current_profile.id}"
        commitment.calendar_label = current_profile.display_name.presence || current_profile.username
      else
        commitment.assignee_profile = nil
        commitment.calendar_key = "person:#{Digest::SHA256.hexdigest("#{current_profile.id}:#{requested_label.downcase}")[0, 16]}"
        commitment.calendar_label = requested_label
      end
    end

    def active_timer_for_calendar?(profile, calendar_key, excluding: nil)
      timers = profile.data_commitments.where(
        calendar_key: calendar_key,
        status: "in_progress",
        actual_ended_at: nil
      )
      timers = timers.where.not(id: excluding.id) if excluding&.persisted?
      timers.exists?
    end

    def commitment_return_path(commitment)
      genera_impresa = commitment.genera_impresa.to_h
      if genera_impresa["project_slug"].present?
        anchor = if genera_impresa["record_type"] == "step_completion" || genera_impresa["task_key"].blank?
          "step-#{genera_impresa['step_key']}"
        else
          "task-#{genera_impresa['step_key']}-#{genera_impresa['task_key']}"
        end
        return posturacorretta_progetto_path(
          genera_impresa.fetch("project_slug"),
          tab: "phases",
          phase: genera_impresa["phase_key"].presence || "implementation",
          anchor: anchor
        )
      end

      tab = %w[completed cancelled].include?(commitment.status) || (commitment.ends_at.present? && commitment.ends_at < Time.current) ? "past" : "upcoming"
      data_commitments_path(tab: tab, anchor: "commitment-#{commitment.id}")
    end

    def available_domains
      return Domain.none unless Current.user
      return Domain.active.where(primary: true).order(:hostname) if Current.user.superadmin_user?

      Domain.active
        .where(id: current_profile.traveler_subscriptions.active.select(:domain_id))
        .order(:hostname)
    end

    def default_domain_for(brand)
      hostname = {
        "posturacorretta" => "posturacorretta.org",
        "generaimpresa" => "generaimpresa.it",
        "impegno" => "impegno.it"
      }[brand]
      @domains.find { |domain| domain.hostname == hostname } if hostname.present?
    end

    def find_genera_impresa_context!
      data = PosturacorrettaProjectCatalog.load
      project = data.fetch("projects", []).find { |item| item["slug"] == params[:project_slug] }
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless project&.dig("generaimpresa_origin") == "generaimpresa"

      step = project.fetch("steps", []).find { |item| item["key"] == params[:step_key] }
      task = step&.fetch("tasks", [])&.find { |item| item["key"] == params[:task_key] } if params[:task_key].present?
      raise ActiveRecord::RecordNotFound, "Step non trovato" unless step
      raise ActiveRecord::RecordNotFound, "Task non trovato" if params[:task_key].present? && task.nil?

      [project, step, task]
    end

    def find_genera_impresa_step!
      data = PosturacorrettaProjectCatalog.load
      project = data.fetch("projects", []).find { |item| item["slug"] == params[:project_slug] }
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless project&.dig("generaimpresa_origin") == "generaimpresa"

      step = project.fetch("steps", []).find { |item| item["key"] == params[:step_key] }
      raise ActiveRecord::RecordNotFound, "Step non trovato" unless step

      [project, step]
    end

    def step_missing_data(step)
      {
        "responsabile" => step["assignee"].blank? || step["assignee"] == "Da assegnare",
        "data di assegnazione" => step["assigned_at"].blank?,
        "costo stimato" => step["estimated_cost"].blank?,
        "tempo stimato" => step["estimated_hours"].blank? && step.fetch("tasks", []).none? { |task| task["estimated_hours"].present? },
        "data di inizio" => step["started_at"].blank?
      }.select { |_label, missing| missing }.keys
    end

    def data_commitment_params
      params.require(:data_commitment).permit(
        :title, :description, :starts_at, :ends_at, :pricing_type,
        :hourly_rate, :total_price, :contribution_type
      )
    end

    def personal_commitment_params
      params.require(:data_commitment).permit(
        :title, :description, :kind, :starts_at, :ends_at, :all_day,
        :actual_started_at, :actual_ended_at, :calendar_label, :domain_id,
        :context_label
      ).except(:domain_id, :context_label)
    end

    def project_path(project, step, task)
      posturacorretta_progetto_path(
        project.fetch("slug"),
        tab: "phases",
        phase: "implementation",
        anchor: "task-#{step.fetch('key')}-#{task.fetch('key')}"
      )
    end


    def project_step_path(project, step)
      posturacorretta_progetto_path(
        project.fetch("slug"),
        tab: "phases",
        phase: "implementation",
        anchor: "step-#{step.fetch('key')}"
      )
    end

    def activity_return_path(project, step, task)
      task ? project_path(project, step, task) : project_step_path(project, step)
    end
    end
  end
end
