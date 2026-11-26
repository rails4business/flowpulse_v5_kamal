module BrandAccesses
  class Authorization
    class NotAuthorized < StandardError; end

    def self.authorize!(actor:, domain:, node: domain&.node, context: nil)
      domain = domain&.canonical_domain_record
      brand = domain&.node
      unless domain&.active? && brand&.brand? && node&.site_node == brand
        raise NotAuthorized, "Il perimetro non appartiene al Brand destinatario"
      end
      raise NotAuthorized, "Chi concede l’accesso non è più attivo" unless actor&.active_registration?

      return if actor&.superadmin_user?

      candidate = context || Current.access_context
      if candidate && (candidate.user != actor || (candidate.brand && candidate.brand != brand))
        raise NotAuthorized, "Il contesto corrente non appartiene a questo Brand"
      end
      current = RoleAssignments::AccessPolicy.current_context(user: actor, context: context)
      if brand.slug == "generaimpresa"
        return if current&.current_role_code == "gestore_generaimpresa" &&
          RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: brand, context: current)

        raise NotAuthorized, "Gli accessi a GeneraImpresa sono approvati dal gestore o dal superadmin"
      end
      # Temporary bridge for structural owners, removed with the legacy migration.
      return if brand.owned_by?(actor)
      return if RoleAssignments::AccessPolicy.allowed?(user: actor, action: :manage_access, node: node, context: context)

      raise NotAuthorized, "Non puoi concedere accesso a questo perimetro"
    end
  end
end
