module Admin
  class ProductionDashboardController < BaseController
    dashboard_section :production

    before_action :require_superadmin!
    before_action :set_workbench_item, only: %i[update_inbox destroy_inbox]

    ITEM_TYPE_OPTIONS = [
      ["Da definire", "undecided"],
      ["Attività", "activity"],
      ["Progetto", "project"],
      ["Skill", "skill"],
      ["Prodotto", "product"],
      ["Evento", "event"],
      ["Evento ripetuto", "recurring_event"]
    ].freeze

    ORGANIZATION_OPTIONS = [
      ["Da decidere", "undecided"],
      ["Da completare", "todo"],
      ["Evento con data", "dated_event"],
      ["Evento ripetuto", "recurring_event"],
      ["Catena produttiva", "production_chain"]
    ].freeze

    CLASSIFICATION_STATUS_OPTIONS = [
      ["Da classificare", "unclassified"],
      ["Parziale", "partial"],
      ["Pronto da collocare", "ready"]
    ].freeze

    def index
      @active_view = params[:view].presence_in(%w[table projects planning]) || "table"
      load_dashboard_options
      @workbench_items = current_profile.data_commitments
        .workbench_items
        .includes(:domain, :subject, :skill_product, :responsible_profile)
        .order(created_at: :desc, id: :desc)
      @production_rows = build_production_rows if @active_view == "projects"
      load_personal_planning if @active_view == "planning"
    end

    def show
      @node = Node.includes(
        :domains,
        :parent,
        :role_assignment,
        reusable_skill_nodes: %i[reusable_skill skill_products],
        node_processes: %i[responsible_profile reference_data_experience]
      ).find(params[:id])
      @brand_node = brand_for(@node)
      @area = params[:area].presence_in(%w[genera rails impegno]) || "genera"
      @skill_activations = @node.reusable_skill_nodes.sort_by { |activation| activation.reusable_skill.title }
      @products = @skill_activations.flat_map(&:skill_products).sort_by { |product| [product.title, product.id] }
      @processes = @node.node_processes.sort_by { |process| [process.title, process.id] }
      @commitments = commitments_for(@node, @products).first(50)
    end

    def create_inbox
      title = params.dig(:workbench_item, :title).to_s.strip
      return redirect_to(table_path, alert: "Scrivi qualcosa da mettere sul Tavolo.") if title.blank?

      domain = fallback_domain
      return redirect_to(table_path, alert: "Configura almeno un dominio attivo prima di usare il Tavolo.") if domain.blank?

      commitment = current_profile.data_commitments.new(
        created_by_profile: current_profile,
        domain: domain,
        assignee_profile: current_profile,
        title: title,
        kind: "work",
        status: "draft",
        starts_at: nil,
        blocks_calendar: false,
        pricing_type: "none",
        contribution_type: "unpaid",
        metadata: {
          "workbench" => {
            "inbox" => true,
            "item_type" => "undecided",
            "organization" => "undecided",
            "classification_status" => "unclassified"
          }
        }
      )

      if commitment.save
        redirect_to table_path, notice: "Voce aggiunta al Tavolo."
      else
        redirect_to table_path, alert: commitment.errors.full_messages.to_sentence
      end
    end

    def update_inbox
      attributes = workbench_item_params
      domain = primary_domains.find_by(id: attributes[:domain_id]) || @workbench_item.domain
      subject = attributes[:subject_node_id].present? ? Node.find_by(id: attributes[:subject_node_id]) : nil
      product = attributes[:skill_product_id].present? ? SkillProduct.includes(:node, :reusable_skill).find_by(id: attributes[:skill_product_id]) : nil
      skill = attributes[:reusable_skill_id].present? ? ReusableSkill.find_by(id: attributes[:reusable_skill_id]) : nil
      responsible = attributes[:responsible_profile_id].present? ? Profile.find_by(id: attributes[:responsible_profile_id]) : nil

      if product.present?
        subject ||= product.node
        if skill.present? && product.reusable_skill != skill
          return redirect_to(table_path, alert: "Il prodotto scelto non appartiene alla Skill indicata.")
        end
        skill ||= product.reusable_skill
      end

      item_type = allowed_value(attributes[:item_type], Brands::Impegno::Commitment::WORKBENCH_ITEM_TYPES, "undecided")
      organization = allowed_value(attributes[:organization], Brands::Impegno::Commitment::WORKBENCH_ORGANIZATIONS, "undecided")
      classification_status = allowed_value(
        attributes[:classification_status],
        Brands::Impegno::Commitment::WORKBENCH_CLASSIFICATION_STATUSES,
        "unclassified"
      )

      metadata = @workbench_item.metadata.to_h.merge(
        "workbench" => @workbench_item.workbench_data.merge(
          "inbox" => true,
          "item_type" => item_type,
          "organization" => organization,
          "classification_status" => classification_status,
          "reusable_skill_id" => skill&.id,
          "product_name" => attributes[:product_name].to_s.strip.presence
        ).compact
      )

      @workbench_item.assign_attributes(
        title: attributes[:title].to_s.strip,
        kind: commitment_kind_for(item_type),
        status: "draft",
        starts_at: nil,
        ends_at: nil,
        blocks_calendar: false,
        domain: domain,
        subject: subject,
        skill_product: product,
        responsible_profile: responsible,
        metadata: metadata
      )

      if @workbench_item.save
        redirect_to table_path, notice: "Voce del Tavolo aggiornata."
      else
        redirect_to table_path, alert: @workbench_item.errors.full_messages.to_sentence
      end
    end

    def destroy_inbox
      @workbench_item.destroy!
      redirect_to table_path, notice: "Voce rimossa dal Tavolo."
    end

    private

      def table_path
        flowpulse_admin_production_path(view: "table")
      end

      def set_workbench_item
        @workbench_item = current_profile.data_commitments.workbench_items.find(params[:id])
      end

      def workbench_item_params
        params.require(:workbench_item).permit(
          :title,
          :item_type,
          :domain_id,
          :subject_node_id,
          :reusable_skill_id,
          :skill_product_id,
          :product_name,
          :responsible_profile_id,
          :organization,
          :classification_status
        )
      end

      def allowed_value(value, allowed_values, fallback)
        value.to_s.presence_in(allowed_values) || fallback
      end

      def commitment_kind_for(item_type)
        case item_type
        when "project" then "project"
        when "event", "recurring_event" then "event"
        else "work"
        end
      end

      def fallback_domain
        canonical = current_domain&.canonical_domain_record
        return canonical if canonical&.active?

        primary_domains.find_by(hostname: "flowpulse.net") || primary_domains.first
      end

      def primary_domains
        @primary_domains ||= Domain.active
          .where(primary: true, canonical_host: [nil, ""])
          .includes(:node)
          .order(:hostname)
      end

      def load_dashboard_options
        @domains = primary_domains
        @nodes = Node.includes(:domains).order(:title, :id)
        @skills = ReusableSkill.order(:title, :id)
        @products = SkillProduct.includes(:node, :reusable_skill).order(:title, :id)
        @profiles = Profile.order(:display_name, :username, :id)
        @item_type_options = ITEM_TYPE_OPTIONS
        @organization_options = ORGANIZATION_OPTIONS
        @classification_status_options = CLASSIFICATION_STATUS_OPTIONS
      end

      def load_personal_planning
        @planning_tab = params[:planning_tab].presence_in(%w[unfinished agenda week]) || "unfinished"
        @selected_date = parse_planning_date
        @week_start = @selected_date.beginning_of_week
        @week_end = @week_start + 6.days

        commitments = current_profile.data_commitments
          .where.not(status: "cancelled")
          .where.not("metadata @> ?", { workbench: { inbox: true } }.to_json)
          .includes(:domain, :subject, :skill_product, :responsible_profile, :data_experience, :data_session, :data_slot, :parent)

        @unfinished_commitments = commitments
          .where.not(status: "completed")
          .to_a
          .sort_by do |commitment|
            start_time = commitment.actual_started_at || commitment.starts_at
            [start_time.present? ? 1 : 0, start_time || Time.zone.at(0), commitment.position, commitment.id]
          end

        range = @week_start.in_time_zone.beginning_of_day..@week_end.in_time_zone.end_of_day
        top_level_commitments = commitments
          .where(parent_id: nil, data_session_id: nil, data_slot_id: nil)
          .where("COALESCE(data_commitments.actual_started_at, data_commitments.starts_at) BETWEEN ? AND ?", range.begin, range.end)

        sessions = personal_sessions_for(range)
        @planning_entries = build_planning_entries(top_level_commitments, sessions)
        @planning_entries_by_day = @planning_entries.group_by { |entry| entry.fetch(:starts_at).in_time_zone.to_date }
        @week_days = (0..6).map { |offset| @week_start + offset.days }
        @week_hours = planning_hours_for(@planning_entries)
        @week_entries_by_slot = @planning_entries.group_by do |entry|
          starts_at = entry.fetch(:starts_at).in_time_zone
          [starts_at.to_date, starts_at.hour]
        end
      end

      def parse_planning_date
        return Date.current if params[:date].blank?

        Date.iso8601(params[:date])
      rescue Date::Error
        Date.current
      end

      def personal_sessions_for(range)
        created_session_ids = DataSession.where(created_by_profile_id: current_profile.id).select(:id)
        linked_session_ids = current_profile.data_commitments.where.not(data_session_id: nil).select(:data_session_id)
        calendar_ids = ProfessionalCalendar.where(created_by_user_id: Current.user.id).select(:id)

        DataSession
          .where(id: created_session_ids)
          .or(DataSession.where(id: linked_session_ids))
          .or(DataSession.where(professional_calendar_id: calendar_ids))
          .where(starts_at: range)
          .where.not(status: "cancelled")
          .includes(:data_experience, professional_calendar: %i[context_node professional_node])
          .order(:starts_at, :position, :id)
      end

      def build_planning_entries(commitments, sessions)
        commitment_entries = commitments.map do |commitment|
          starts_at = commitment.actual_started_at || commitment.starts_at
          ends_at = commitment.actual_ended_at || commitment.ends_at
          {
            record_type: "commitment",
            record: commitment,
            title: commitment.title,
            starts_at: starts_at,
            ends_at: ends_at,
            context: [commitment.domain&.display_hostname, commitment.data_experience&.title].compact_blank.join(" · "),
            color: planning_color_for(commitment.domain&.auth_slug)
          }
        end

        session_entries = sessions.map do |session|
          calendar = session.professional_calendar
          {
            record_type: "session",
            record: session,
            title: session.title,
            starts_at: session.starts_at,
            ends_at: session.ends_at,
            context: [calendar&.display_label, session.data_experience&.title].compact_blank.join(" · "),
            color: calendar&.color.presence || "slate"
          }
        end

        (commitment_entries + session_entries).sort_by do |entry|
          [entry.fetch(:starts_at), entry.fetch(:record_type), entry.fetch(:record).id]
        end
      end

      def planning_hours_for(entries)
        start_hours = entries.filter_map { |entry| entry[:starts_at]&.in_time_zone&.hour }
        end_hours = entries.filter_map { |entry| entry[:ends_at]&.in_time_zone&.hour }
        first_hour = [8, start_hours.min || 8].min.clamp(0, 23)
        last_hour = [20, end_hours.max || start_hours.max || 20].max.clamp(first_hour, 23)

        (first_hour..last_hour).to_a
      end

      def planning_color_for(domain_slug)
        case domain_slug.to_s
        when /posturacorretta/ then "blue"
        when /percorso-?integrato/ then "teal"
        when /cantachetipassa/ then "orange"
        when /giardino/ then "violet"
        when /generaimpresa|rails4b|rails4business/ then "amber"
        else "slate"
        end
      end

      def build_production_rows
        nodes = Node.project.includes(
          :domains,
          :parent,
          role_assignment: :profile,
          reusable_skill_nodes: %i[reusable_skill skill_products],
          node_processes: :responsible_profile
        ).order(:title, :id).to_a
        nodes_by_id = Node.includes(:domains).index_by(&:id)
        product_ids = nodes.flat_map { |node| node.reusable_skill_nodes.flat_map { |activation| activation.skill_products.map(&:id) } }
        node_ids = nodes.map(&:id)

        node_commitments = Brands::Impegno::Commitment
          .where(subject_type: "Node", subject_id: node_ids)
          .includes(:assignee_profile, :responsible_profile)
          .order(updated_at: :desc)
          .group_by(&:subject_id)
        product_commitments = Brands::Impegno::Commitment
          .where(skill_product_id: product_ids)
          .includes(:assignee_profile, :responsible_profile)
          .order(updated_at: :desc)
          .group_by(&:skill_product_id)

        nodes.filter_map do |node|
          brand = brand_for(node, nodes_by_id: nodes_by_id)
          next if brand.blank? || !brand.project?

          activations = node.reusable_skill_nodes.to_a
          products = activations.flat_map(&:skill_products)
          processes = node.node_processes.to_a
          commitments = node_commitments.fetch(node.id, []) + products.flat_map { |product| product_commitments.fetch(product.id, []) }
          last_commitment = commitments.max_by(&:updated_at)
          next unless node == brand || activations.any? || processes.any? || products.any? || last_commitment.present?

          people = [
            node.role_assignment&.profile,
            *processes.map(&:responsible_profile),
            *products.map(&:created_by_profile),
            *commitments.flat_map { |commitment| [commitment.responsible_profile, commitment.assignee_profile] }
          ].compact.uniq

          {
            node: node,
            brand: brand,
            domain: brand.domains.select(&:active?).find(&:primary?) || brand.domains.select(&:active?).first,
            activations: activations,
            products: products,
            processes: processes,
            people: people,
            last_commitment: last_commitment
          }
        end.sort_by { |row| [row[:brand].title, row[:node] == row[:brand] ? "" : row[:node].title] }
      end

      def brand_for(node, nodes_by_id: nil)
        nodes_by_id ||= Node.includes(:domains).index_by(&:id)
        current = node
        while current.present?
          active_domains = current.domains.select(&:active?)
          return current if active_domains.any?

          current = nodes_by_id[current.parent_id]
        end
      end

      def commitments_for(node, products)
        by_node = Brands::Impegno::Commitment.where(subject: node)
        by_product = Brands::Impegno::Commitment.where(skill_product_id: products.map(&:id))
        Brands::Impegno::Commitment
          .where(id: by_node.select(:id))
          .or(Brands::Impegno::Commitment.where(id: by_product.select(:id)))
          .includes(:assignee_profile, :responsible_profile, :domain, :skill_product)
          .order(updated_at: :desc, id: :desc)
      end
  end
end
