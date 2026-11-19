module PublicNodePresentation
  extend ActiveSupport::Concern

  private
    def prepare_public_node(node, navigation_domain: nil, domain_root: nil)
      @node = node
      @node.build_content if @node.content.blank?
      @children = public_node_accessible_children(@node)

      @navigation_domain = navigation_domain || public_node_navigation_domain(@node)
      @navigation_root_node = @navigation_domain&.node
      @navigation_source_node = @node.navigation_source_node
      boundary_node = @navigation_root_node
      @current_host_domain_root = domain_root.nil? ? public_node_domain_root?(@node) : domain_root
      @public_navigation_ancestor_ids = @node.self_and_ancestors.map(&:id)
      @public_navigation_items = resolve_public_navigation(public_navigation_source_items(@node.effective_navigation_items))

      all_ancestors = @node.self_and_ancestors.reverse
      @breadcrumbs = if boundary_node.present?
        all_ancestors.drop_while { |ancestor| ancestor != boundary_node }
      else
        all_ancestors
      end

      parent_scope = public_node_parent_scope(boundary_node)
      @siblings = parent_scope.order(:position, :title).select { |candidate| public_node_navigable?(candidate) }
      current_index = @siblings.index(@node)
      @previous_sibling = @siblings[current_index - 1] if current_index&.positive?
      @next_sibling = @siblings[current_index + 1] if current_index
      @parent_node = public_node_parent_navigation_node(boundary_node)
      @can_manage_public_node = public_node_creator_owner?
      set_public_node_brand_access_context
    end

    def public_node_navigation_domain(node)
      ancestors = node.self_and_ancestors.to_a
      current = current_domain

      if current&.node_id.present? && ancestors.any? { |ancestor| ancestor.id == current.node_id }
        return current
      end

      ancestor_ids = ancestors.map(&:id)
      Domain.active.where(node_id: ancestor_ids).includes(:node).to_a.min_by do |domain|
        ancestor_ids.index(domain.node_id)
      end
    end

    def resolve_public_navigation(items)
      Array(items).filter_map do |item|
        next if item["audience"] == "superadmin" && !Current.user&.superadmin_user?

        target = @node.role_assignment.nodes.find_by(slug: item["slug"]) if item["slug"].present?
        next if item["slug"].present? && (target.blank? || !public_node_navigable?(target))

        node = target&.bridge_node? ? target.resolve_target : target
        children = resolve_public_navigation(item["children"])
        home = item["home"] == true

        {
          node: node,
          label: item["label"].presence || target&.title,
          group: item["group"] == true,
          home: home,
          path: item["path"].presence,
          current: public_navigation_current?(node, home) || public_navigation_path_current?(item["path"]) || children.any? { |child| child[:current] },
          children: children
        }
      end
    end

    # Compatibilità con cataloghi già importati: raggruppa le tre fasi anche
    # prima del successivo sync di config/nodes.yml.
    def public_navigation_source_items(items)
      items = Array(items)
      return items unless @navigation_root_node&.slug == "posturacorretta"

      path_keys = %w[home percorso espressione consapevolezza connessione]
      home_index = items.index { |item| item["key"].in?(path_keys) } || 0
      items = items.reject { |item| item["key"].in?(["partecipa", *path_keys]) }
      items.insert(home_index, { "key" => "home", "label" => "Home", "path" => "/posturacorretta" })
      items = items.reject { |item| item["key"].in?(%w[insegnanti centri]) }
      items.insert(home_index + 1, { "key" => "insegnanti", "label" => "Insegnanti", "path" => "/posturacorretta/insegnanti" })
      items.insert(home_index + 2, { "key" => "centri", "label" => "Centri", "path" => "/posturacorretta/centri" })

      items.map do |item|
        normalized = item["key"].in?(%w[partecipa servizi about]) ? item.except("children", "group") : item.dup
        normalized
      end.then do |normalized_items|
        explore = {
          "key" => "esplora", "label" => "Esplora", "group" => true, "audience" => "superadmin",
          "children" => [
            { "key" => "contenuti", "label" => "Contenuti", "path" => "/posturacorretta/contenuti" },
            { "key" => "eventi", "label" => "Eventi", "path" => "/posturacorretta/eventi" },
            { "key" => "libri", "label" => "Libri", "path" => "/posturacorretta/libri" },
            {
              "key" => "strumenti-interni", "label" => "Strumenti interni", "group" => true, "audience" => "superadmin",
              "children" => [
                { "key" => "archivio-didattico", "label" => "Archivio didattico", "path" => "/posturacorretta/accademia" },
                { "key" => "tre-progetti", "label" => "I tre progetti", "path" => "/posturacorretta/tre-progetti" },
                { "key" => "collabora", "label" => "Collabora", "path" => "/posturacorretta/collabora" },
                { "key" => "area-corsi", "label" => "Area corsi", "path" => "/posturacorretta/lezioni" },
                { "key" => "area-insegnanti", "label" => "Area insegnanti", "path" => "/posturacorretta/area-insegnanti" },
                { "key" => "visione-progetto", "label" => "Visione e progetto · Bozza", "path" => "/posturacorretta/guida?sezione=progetto" }
              ]
            }
          ]
        }
        if normalized_items.any? { |item| item["key"] == "esplora" }
          normalized_items.map { |item| item["key"] == "esplora" ? explore : item }
        else
          normalized_items + [explore]
        end
      end
    end

    # La voce è selezionata sul suo nodo e sulle pagine sotto di esso; la voce home sulla home del dominio.
    def public_navigation_current?(node, home)
      return @current_host_domain_root == true if home
      return false if node.blank?

      @public_navigation_ancestor_ids.include?(node.id)
    end

    def public_navigation_path_current?(path)
      path.present? && request.path == URI.parse(path).path
    rescue URI::InvalidURIError
      false
    end

    def prepare_posturacorretta_home(node)
      return unless node.slug == "posturacorretta"

      @posturacorretta_home = Posturacorretta::HomeJourney.new(
        tappa: params[:tappa],
        tab: params[:tab],
        risorsa: params[:risorsa],
        completed_chapters: posturacorretta_completed_chapters
      )
    end

    def prepare_posturacorretta_consapevolezza(node)
      return unless node.slug == "apprendimento-2-connessione"

      data = PosturacorrettaMethodologies.load
      @consapevolezza_tab = params[:tab].to_s.presence_in(%w[corso metodiche percorsi]) || "corso"
      @consapevolezza_course = Posturacorretta::ContentRepository.new(include_scheduled: true)
        .course_by_id("muoviti-ed-esplora")
      @consapevolezza_path_tab = params[:percorso].to_s.presence_in(%w[persone attivita problemi]) || "persone"
      @consapevolezza_methodologies = data.fetch("methodologies")
      @consapevolezza_path_groups = [
        {
          key: "persone",
          label: "Persone e fasi della vita",
          description: "Percorsi pensati per età, momenti di cambiamento e bisogni delle persone.",
          node: node.self_and_descendants.find_by(slug: "eta")
        },
        {
          key: "attivita",
          label: "Attività e contesti",
          description: "Percorsi collegati al lavoro, alla vita quotidiana, allo sport e agli ambienti frequentati.",
          node: node.self_and_descendants.find_by(slug: "attivita-e-contesti")
        },
        {
          key: "problemi",
          label: "Problemi ed esigenze",
          description: "Percorsi educativi per orientarsi tra condizioni, sintomi ed esigenze specifiche.",
          node: node.self_and_descendants.find_by(slug: "condizioni-e-patologie")
        }
      ]
    end

    def prepare_posturacorretta_connessione(node)
      return unless node.slug == "dalla-posturacorretta-al-giardino-del-corpo"

      @connessione_tab = params[:tab].to_s.presence_in(%w[corpo risorse]) || "corpo"
      repository = Posturacorretta::ContentRepository.new(include_scheduled: true)
      @connessione_courses = {
        "corpo" => repository.course_by_id("corpo-come-un-giardino"),
        "risorse" => repository.course_by_id("ascolta-gli-aspetti-vitali")
      }
    end

    def prepare_posturacorretta_public_section(node)
      return unless node.slug.in?(%w[partecipa-posturacorretta servizi-posturacorretta about-posturacorretta])

      @posturacorretta_public_section = node.slug.delete_suffix("-posturacorretta")
      @faq_items = posturacorretta_faq_items if node.slug == "about-posturacorretta"
      @posturacorretta_teacher_node = node.self_and_descendants.find_by(slug: "diventa-insegnante-posturacorretta") || Node.find_by(slug: "diventa-insegnante-posturacorretta") if node.slug == "about-posturacorretta"
    end

    def posturacorretta_faq_items
      docs_root = Rails.root.join("config/data/brands/percorso-integrato/docs/02_persone").cleanpath
      [
        ["Da dove comincio?", "01_da_dove_comincio.md"],
        ["Posso iniziare senza una diagnosi?", "02_senza_diagnosi.md"],
        ["Che differenza c’è tra insegnante e professionista?", "03_insegnante_professionista.md"],
        ["Posso coinvolgere il mio professionista?", "04_coinvolgere_professionista.md"],
        ["Quanto dura un programma?", "05_durata_programma.md"]
      ].map do |question, filename|
        path = docs_root.join(filename).cleanpath
        body = path.to_s.start_with?("#{docs_root}/") && path.file? ? path.read.sub(/\A# .+\n+/, "") : ""
        { question: question, answer: body }
      end
    end

    def posturacorretta_completed_chapters
      domain = Domain.find_for_host("posturacorretta.org")
      return {} unless current_profile && domain

      current_profile.data_commitments.where(domain: domain, kind: "academy", status: "completed").includes(content: :parent).to_a
        .select(&:chapter_completion?)
        .group_by(&:learning_course_slug)
        .transform_values { |items| items.map(&:learning_slug).uniq }
    end

    def public_node_domain_root?(node)
      current = current_domain
      return current.node_id == node.id if current.present?

      @navigation_domain&.node_id == node.id
    end

    def public_node_parent_scope(boundary_node)
      if @current_host_domain_root
        Node.where(id: boundary_node&.id || @node.id)
      elsif @node.parent.present?
        @node.parent.children
      elsif boundary_node.present?
        Node.where(id: boundary_node.id)
      else
        Node.roots.where(role_assignment_id: @node.role_assignment_id)
      end
    end

    def public_node_parent_navigation_node(boundary_node)
      return nil if @node.parent_id.blank? || @current_host_domain_root

      parent = @node.parent
      return nil if parent.blank? || !public_node_visible?(parent)
      return nil if boundary_node.present? && !parent.self_and_ancestors.exists?(id: boundary_node.id)

      parent
    end

    def public_node_creator_owner?
      return false unless NodeCatalogEditor.enabled? && Current.user.present?
      return true if Current.user.superadmin_user?

      Current.user.ideatore_user? && Current.user.role_assignments.ideatore.exists?(id: @node.role_assignment_id)
    end

    def set_public_node_brand_access_context
      @brand_access_domain = public_node_brand_access_domain(@node)
      return if @brand_access_domain.blank? || Current.user.blank?

      @brand_access = Current.user.profile&.brand_accesses&.active&.find_by(brand_node_id: @brand_access_domain.node_id)
    end

    def public_node_brand_access_domain(node)
      current = current_domain
      if current&.node_id.present? && node.self_and_ancestors.exists?(id: current.node_id)
        return current
      end

      return @navigation_domain if @navigation_domain&.node_id.present?

      node.domains.active.order(primary: :desc, hostname: :asc).first
    end
end
