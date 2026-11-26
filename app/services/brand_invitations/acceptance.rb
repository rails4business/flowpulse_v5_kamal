module BrandInvitations
  class Acceptance
    class Invalid < StandardError; end
    Result = Data.define(:user, :brand_access, :brand_credential)

    def initialize(invitation:, domain:)
      @invitation = invitation
      @domain = domain&.canonical_domain_record
    end

    def register!(user:, password:, password_confirmation:)
      complete!(user: user) do |access|
        if access.brand_credential
          raise Invalid, "Esiste già una credenziale per questo Brand. Accedi con la password esistente."
        end

        access.create_brand_credential!(
          brand_node: @invitation.brand_node, email_address: @invitation.email_address,
          password: password, password_confirmation: password_confirmation, email_verified_at: Time.current
        )
      end
    end

    def accept!(user:, credential:)
      complete!(user: user) do |access|
        credential.reload
        unless credential.brand_access_id == access.id && credential.active?
          raise Invalid, "La credenziale non è attiva per questo accesso al Brand."
        end

        credential
      end
    end

    private

      def complete!(user:)
        BrandInvitation.transaction do
          request = @invitation.brand_request
          request&.lock!
          @invitation.lock!
          validate_invitation!(request)
          user.lock! if user.persisted?
          validate_user!(user)
          if user.new_record?
            user.password = user.password_confirmation = SecureRandom.base58(48)
            user.registration_status = "active"
            user.save!
          end
          profile = user.profile || user.create_profile!(display_name: user.email_address.split("@").first)
          profile.lock!
          if request&.requester_profile_id && request.requester_profile_id != profile.id
            raise Invalid, "La richiesta è già collegata a un altro Profile."
          end

          access = profile.brand_accesses.find_by(brand_node: @invitation.brand_node)
          access&.lock!
          if access && !access.active? && access.updated_at > @invitation.created_at
            raise Invalid, "L’accesso è stato revocato dopo questo invito. Richiedi un nuovo invito."
          end
          node = request&.subject.is_a?(Node) ? request.subject : @invitation.brand_node
          actor = @invitation.invited_by_user
          context = issuer_context
          access = BrandAccesses::Manager.new(actor: actor, context: context).grant!(
            profile: profile, domain: @domain, authorization_node: node, managed_by_grants: true
          )
          credential = yield access
          BrandAccessGrants::Manager.new(actor: actor, context: context).grant!(brand_access: access, node: node, brand_request: request)
          @invitation.accept!(user)
          if request
            request.update!(requester_profile: profile, status: "accepted", resolved_at: Time.current)
          end
          Brands::Impegno::Commitment
            .where("metadata ->> 'brand_invitation_id' = ?", @invitation.id.to_s)
            .update_all(status: "completed", resolved_at: Time.current, updated_at: Time.current)
          Result.new(user: user, brand_access: access, brand_credential: credential)
        end
      end

      def validate_invitation!(request)
        unless @invitation.pending? && @domain&.active? && @domain.node_id == @invitation.brand_node_id
          raise Invalid, "L’invito è scaduto o non è valido per questo Brand."
        end
        if request && (!request.active? || request.kind != "access" || request.brand_node_id != @domain.node_id)
          raise Invalid, "La richiesta collegata non è più valida per questo Brand."
        end

        node = request&.subject.is_a?(Node) ? request.subject : @invitation.brand_node
        BrandAccesses::Authorization.authorize!(actor: @invitation.invited_by_user, domain: @domain, node: node, context: issuer_context)
      end

      def issuer_context
        AccessContext::Resolver.new(user: @invitation.invited_by_user, domain: @domain).resolve
      end

      def validate_user!(user)
        unless @invitation.email_address.casecmp?(user.email_address.to_s.strip)
          raise Invalid, "L’email deve coincidere con l’indirizzo invitato."
        end
        if user.persisted? && !user.active_registration?
          raise Invalid, "Questo account globale è sospeso."
        end
      end
  end
end
