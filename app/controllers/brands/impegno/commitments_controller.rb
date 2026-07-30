require "digest"

module Brands
  module Impegno
    class CommitmentsController < ApplicationController
      layout "landing"

  def index
    @scoped_domain = current_domain if current_domain&.target_controller == "brands/posturacorretta" || current_domain&.target_action == "posturacorretta"
    @domains = available_domains

    @profile = Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
    @commitments = @profile.data_commitments.includes(:domain).order(:starts_at)
    @commitments = @commitments.where(domain: @scoped_domain) if @scoped_domain
    @past_commitments = @commitments.select do |commitment|
      %w[completed cancelled].include?(commitment.status) || (!commitment.tracking? && commitment.ends_at.present? && commitment.ends_at < Time.current)
    end
    @upcoming_commitments = @commitments - @past_commitments
    @commitment_tab = %w[upcoming past].include?(params[:tab]) ? params[:tab] : "upcoming"
    @commitment_date = Date.iso8601(params[:date]) if params[:date].present?
    @visible_commitments = @commitment_tab == "past" ? @past_commitments.reverse : @upcoming_commitments
    @visible_commitments = @visible_commitments.select { |commitment| commitment.starts_at.to_date == @commitment_date } if @commitment_date
  rescue Date::Error
    redirect_to data_commitments_path(tab: @commitment_tab), alert: "La data indicata non è valida."
  end

  def create
    return create_personal_commitment unless params[:project_slug].present?

    return redirect_to(data_commitments_path, alert: "Solo il superadmin può registrare attività GeneraImpresa.") unless Current.user&.superadmin_user?

    project, step, task = find_genera_impresa_context!
    profile = current_profile
    domain = current_domain || Domain.find_for_host("posturacorretta.org")
    raise ActiveRecord::RecordNotFound, "Dominio PosturaCorretta non configurato" unless domain

    start_now = ActiveModel::Type::Boolean.new.cast(params[:start_now])
    if start_now && profile.data_commitments.where(status: "in_progress", actual_ended_at: nil).exists?
      return redirect_to project_path(project, step, task), alert: "Hai già un’attività in corso. Concludila prima di iniziarne un’altra."
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
      return redirect_to(project_path(project, step, task), alert: "Scrivi cosa stai per fare.") if activity_description.blank?

      commitment.title = task.fetch("title")
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
      "task_key" => task.fetch("key")
    }

    if commitment.save
      notice = start_now ? "Timer avviato." : "Attività registrata nel calendario."
      redirect_to project_path(project, step, task), notice: notice
    else
      redirect_to project_path(project, step, task), alert: commitment.errors.full_messages.to_sentence
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

  def destroy
    commitment = owned_commitment
    return_path = commitment_return_path(commitment)
    commitment.destroy!
    redirect_to return_path, notice: "Impegno eliminato."
  end

  private

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
        if current_profile.data_commitments.where(status: "in_progress", actual_ended_at: nil).exists?
          return redirect_to data_commitments_path(tab: "upcoming"), alert: "Hai già un’attività in corso. Concludila prima di registrarne un’altra."
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
        redirect_to data_commitments_path(tab: "upcoming"), notice: notice
      else
        redirect_to data_commitments_path, alert: commitment.errors.full_messages.to_sentence
      end
    end

    def current_profile
      Current.user.profile || Current.user.create_profile!(display_name: Current.user.email_address.to_s.split("@").first)
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

    def commitment_return_path(commitment)
      genera_impresa = commitment.genera_impresa.to_h
      if genera_impresa["project_slug"].present?
        return posturacorretta_progetto_path(
          genera_impresa.fetch("project_slug"),
          tab: "phases",
          phase: genera_impresa["phase_key"].presence || "implementation",
          anchor: "task-#{genera_impresa['step_key']}-#{genera_impresa['task_key']}"
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

    def find_genera_impresa_context!
      data = PosturacorrettaProjectCatalog.load
      project = data.fetch("projects", []).find { |item| item["slug"] == params[:project_slug] }
      raise ActiveRecord::RecordNotFound, "Progetto non trovato" unless project&.dig("generaimpresa_origin") == "generaimpresa"

      step = project.fetch("steps", []).find { |item| item["key"] == params[:step_key] }
      task = step&.fetch("tasks", [])&.find { |item| item["key"] == params[:task_key] }
      raise ActiveRecord::RecordNotFound, "Step o task non trovato" unless step && task

      [project, step, task]
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
        :actual_started_at, :actual_ended_at, :calendar_label
      )
    end

    def project_path(project, step, task)
      posturacorretta_progetto_path(
        project.fetch("slug"),
        tab: "phases",
        phase: "implementation",
        anchor: "task-#{step.fetch('key')}-#{task.fetch('key')}"
      )
    end
    end
  end
end
