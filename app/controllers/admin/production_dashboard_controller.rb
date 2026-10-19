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
      @active_view = params[:view].presence_in(%w[table projects]) || "table"
      load_dashboard_options
      @workbench_items = current_profile.data_commitments
        .workbench_items
        .includes(:domain, :subject, :skill_product, :responsible_profile)
        .order(created_at: :desc, id: :desc)
      @production_rows = build_production_rows if @active_view == "projects"
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
