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
    @impegno_professional_access = Current.user&.superadmin_user? ||
      Current.user&.role_assignments&.where(role: :operator)&.exists? || false
    @agenda_filter = @active_area == "agenda" && @active_view == "agenda" && @impegno_professional_access ? params[:agenda_filter].presence_in(%w[all events booking_slots]) || "all" : nil

    # Il calendario è unico: il dominio è un contesto del commitment, non un calendario separato.
    @default_brand = params[:default_brand].to_s.strip.presence || "impegno"
    @default_domain = default_domain_for(@default_brand)
    @commitment_node_options = available_commitment_nodes
    @default_commitment_node = @default_domain&.node

    @profile = current_profile
    @commitments = @profile.data_commitments.includes(:domain, :participant_contact, :assignee_profile, :created_by_profile, :data_experience, :data_session, :data_slot).order(:starts_at)
    @agenda_date = parse_agenda_date
    if params[:view_mode] == "weekplan"
      @week_start = (@agenda_date || Date.current).beginning_of_week
      @week_end = @week_start + 6.days
      @data_sessions = visible_week_sessions(@week_start, @week_end)
      @commitments = @commitments.select do |commitment|
        date = (commitment.actual_started_at || commitment.starts_at)&.in_time_zone&.to_date
        date && date.between?(@week_start, @week_end)
      end
    elsif @agenda_date
      @commitments = @commitments.select do |commitment|
        (commitment.actual_started_at || commitment.starts_at)&.in_time_zone&.to_date == @agenda_date
      end
    elsif params[:period] == "upcoming"
      @commitments = @commitments.select do |commitment|
        starts_at = commitment.actual_started_at || commitment.starts_at
        starts_at.present? && starts_at >= Time.current
      end
    elsif params[:period] == "past"
      @commitments = @commitments.select do |commitment|
        starts_at = commitment.actual_started_at || commitment.starts_at
        starts_at.present? && starts_at < Time.current
      end
    end
    if @agenda_filter == "events"
      @commitments = @commitments.select { |commitment| commitment.kind == "event" }
    elsif @agenda_filter == "booking_slots"
      @commitments = @commitments.select { |commitment| ActiveModel::Type::Boolean.new.cast(commitment.metadata.to_h["booking_slot"]) }
    end
    @commitments = @commitments.reject { |commitment| commitment.status == "cancelled" } if params[:view_mode] == "weekplan"

    # Raggruppa i commitment per giorno
    @commitments_by_day = @commitments.group_by do |commitment|
      (commitment.actual_started_at || commitment.starts_at)&.in_time_zone&.to_date
    end
  end

  def create
    return create_publication_decision if ActiveModel::Type::Boolean.new.cast(params[:publication_decision])
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

    attributes = personal_commitment_params
    subject_node_id = attributes.delete(:subject_node_id)
    skill_product_id = attributes.delete(:skill_product_id)
    commitment.assign_attributes(attributes)
    commitment.domain = domain
    assign_subject_node(commitment, subject_node_id, domain:, preserve_if_blank: true)
    commitment.skill_product = skill_product_for(skill_product_id, commitment.subject) if skill_product_id.present?
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

    def create_publication_decision
      brand = params[:context_brand].to_s.strip.presence || params[:default_brand].to_s.strip.presence
      domain = default_domain_for(brand)
      return redirect_to(personal_commitment_return_path, alert: "Il dominio del contenuto non è disponibile.") unless domain

      attributes = params.require(:data_commitment).permit(
        :title, :content_key, :publication_change_kind, :publication_note_md,
        :publication_status, :publication_visibility, :subject_node_id, :skill_product_id,
        access_modes: []
      )
      subject_node_id = attributes.delete(:subject_node_id)
      subject = subject_node_id.present? ? available_commitment_nodes.find_by(id: subject_node_id) : nil
      subject ||= domain.node
      unless publication_manageable_by_current_user?(domain, subject)
        return redirect_to personal_commitment_return_path, alert: "Non hai i permessi per approvare questo contenuto."
      end

      change_kind = attributes[:publication_change_kind].presence_in(Commitment::PUBLICATION_CHANGE_KINDS) || "publish"
      publication_status = attributes[:publication_status].presence_in(Commitment::PUBLICATION_STATUSES) || publication_status_for(change_kind)
      publication_visibility = attributes[:publication_visibility].presence_in(Commitment::PUBLICATION_VISIBILITIES) || "public"
      access_modes = Array(attributes[:access_modes]).compact_blank
      access_modes = ["free"] if access_modes.empty?
      now = Time.current

      commitment = Commitment.new(
        profile: current_profile,
        created_by_profile: current_profile,
        domain: domain,
        subject: subject,
        skill_product: skill_product_for(attributes[:skill_product_id], subject),
        title: attributes[:title],
        kind: "content",
        status: "completed",
        starts_at: now,
        blocks_calendar: false,
        pricing_type: "none",
        contribution_type: "unpaid",
        content_key: attributes[:content_key],
        publish_on_completion: true,
        publication_status: publication_status,
        publication_visibility: publication_visibility,
        publication_change_kind: change_kind,
        publication_note_md: attributes[:publication_note_md],
        access_modes: access_modes,
        published_at: (now if publication_status == "published"),
        published_by_profile: current_profile,
        metadata: { "content_path" => safe_return_path }
      )
      assign_previous_publication_commitment(commitment)
      assign_calendar_identity(commitment)

      if commitment.save
        redirect_to personal_commitment_return_path, notice: publication_decision_notice(publication_status)
      else
        redirect_to personal_commitment_return_path, alert: commitment.errors.full_messages.to_sentence
      end
    end

    def publication_manageable_by_current_user?(domain, subject)
      return true if Current.user&.superadmin_user?

      domain.node&.administered_by?(Current.user) || subject&.administered_by?(Current.user) || false
    end

    def skill_product_for(requested_id, subject)
      return if requested_id.blank?

      product = SkillProduct.includes(:node).find_by(id: requested_id)
      return product if product && product.node == subject

      nil
    end

    def publication_status_for(change_kind)
      return "archived" if change_kind == "archive"
      return "draft" if change_kind == "unpublish"

      "published"
    end

    def publication_decision_notice(publication_status)
      case publication_status
      when "published" then "Pubblicazione approvata."
      when "archived" then "Contenuto archiviato."
      else "Contenuto riportato in bozza."
      end
    end

    def safe_return_path
      candidate = params[:return_to].to_s
      return candidate if candidate.start_with?("/") && !candidate.start_with?("//")

      nil
    end

    def parse_agenda_date
      return if params[:date].blank?

      Date.iso8601(params[:date])
    rescue Date::Error
      nil
    end

    def create_personal_commitment
      context_brand = params[:context_brand].to_s.strip.presence
      domain = if context_brand
        default_domain_for(context_brand)
      else
        # Compatibilità per richieste già esistenti: l'interfaccia corrente
        # invia sempre context_brand e non consente di scegliere il tag.
        available_domains.find_by(id: params.dig(:data_commitment, :domain_id))
      end
      return redirect_to(personal_commitment_return_path, alert: "Il dominio del contesto non è disponibile.") unless domain

      attributes = personal_commitment_params
      subject_node_id = attributes.delete(:subject_node_id)
      skill_product_id = attributes.delete(:skill_product_id)
      commitment = Commitment.new(attributes)
      commitment.profile = current_profile
      commitment.created_by_profile = current_profile
      commitment.domain = domain
      assign_subject_node(commitment, subject_node_id, domain:)
      commitment.skill_product = skill_product_for(skill_product_id, commitment.subject) if skill_product_id.present?
      assign_previous_publication_commitment(commitment)
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
      commitment.data_experience = selected_experience
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

    def selected_experience
      experience_id = params.dig(:data_commitment, :data_experience_id).presence
      return if experience_id.blank?
      return DataExperience.find(experience_id) if Current.user&.superadmin_user?

      nil
    end

    def visible_week_sessions(week_start, week_end)
      return DataSession.none unless Current.user&.superadmin_user?

      DataSession.includes(:data_experience, professional_calendar: :context_node)
        .where(starts_at: week_start.in_time_zone.beginning_of_day..week_end.in_time_zone.end_of_day)
        .order(:starts_at, :position)
    end

    def personal_commitment_return_path
      return safe_return_path if safe_return_path

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

      period = %w[completed cancelled].include?(commitment.status) || (commitment.ends_at.present? && commitment.ends_at < Time.current) ? "past" : "upcoming"
      brand = brand_context_for(commitment.domain)
      impegno_path(brand:, area: "agenda", period:, anchor: "commitment-#{commitment.id}")
    end

    def brand_context_for(domain)
      domain = domain&.canonical_domain_record
      hostname_brand = Brands::Impegno::HomeController::DOMAIN_BRANDS[domain&.hostname.to_s.sub(/\Awww\./, "")]
      domain&.auth_slug.presence || domain&.site_key.presence || hostname_brand || domain&.node&.slug || "impegno"
    end

    def available_domains
      return Domain.none unless Current.user
      return Domain.active.where(primary: true).order(:hostname) if Current.user.superadmin_user?

      Domain.active
        .where(primary: true, node_id: current_profile.brand_accesses.active.select(:brand_node_id))
        .order(:hostname)
    end

    def default_domain_for(brand)
      domains = @domains || available_domains
      requested_brand = brand == "personale" ? "impegno" : brand.to_s.tr("_", "-")
      domains.find { |domain| brand_context_for(domain).to_s.tr("_", "-") == requested_brand }
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
        :context_label, :data_experience_id, :content_key, :publish_on_completion, :skill_product_id,
        :publication_status, :publication_visibility, :publication_change_kind,
        :publication_note_md, :subject_node_id, access_modes: []
      ).except(:domain_id, :context_label)
    end

    def assign_subject_node(commitment, requested_id, domain:, preserve_if_blank: false)
      return if preserve_if_blank && requested_id.blank?

      node_id = requested_id.presence || domain.node_id
      commitment.subject = node_id.present? ? available_commitment_nodes.find(node_id) : nil
    end

    def assign_previous_publication_commitment(commitment)
      return unless commitment.kind == "content" && commitment.content_key.present? && commitment.domain

      commitment.previous_publication_commitment = Commitment
        .where(domain: commitment.domain, kind: "content", content_key: commitment.content_key)
        .where(subject: commitment.subject)
        .order(created_at: :desc, id: :desc)
        .first
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
