# Collega al profilo le richieste che non ne hanno uno (aperte o chiuse, lo stato non cambia).
#
# - "invito": la richiesta ha un invito accettato → profilo di chi l'ha accettato.
# - "email verificata" / "invito a questa email": l'email del contatto è quella di un utente
#   di cui l'indirizzo è affidabile.
# - Le altre corrispondenze per email non vengono collegate: finiscono tra quelle da controllare.
class BrandRequestProfileLinker
  Match = Struct.new(:brand_request, :profile, :reason, keyword_init: true)

  attr_reader :linked, :to_review

  def initialize(scope: BrandRequest.all)
    @scope = scope
    @linked = []
    @to_review = []
  end

  def call(apply: false)
    @scope.where(requester_profile_id: nil).includes(:domain, :participant_contact, :brand_invitations).find_each do |brand_request|
      match = match_for(brand_request)
      next unless match

      if match.reason
        brand_request.update!(requester_profile: match.profile) if apply
        @linked << match
      else
        @to_review << match
      end
    end
    self
  end

  private

    def match_for(brand_request)
      accepted = brand_request.brand_invitations.select { |invitation| invitation.status == "accepted" && invitation.accepted_by_user_id }
      if (invitation = accepted.max_by(&:accepted_at)) && (profile = invitation.accepted_by_user&.profile)
        return Match.new(brand_request:, profile:, reason: "invito")
      end

      email = brand_request.participant_contact&.email.to_s.strip.downcase
      return if email.blank?

      user = User.find_by(email_address: email)
      return if user&.profile.blank?

      Match.new(brand_request:, profile: user.profile, reason: trusted_email_reason(user))
    end

    def trusted_email_reason(user)
      return "email verificata" if user.email_verified?

      "invito a questa email" if BrandInvitation.where(status: "accepted", accepted_by_user: user, email_address: user.email_address).exists?
    end
end
