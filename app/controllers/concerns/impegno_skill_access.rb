module ImpegnoSkillAccess
  extend ActiveSupport::Concern

  included do
    helper_method :current_impegno_skill_activation
  end

  private

    def impegno_skill
      @impegno_skill ||= ReusableSkill.find_by(slug: "1impegno", resource_type: "DataCommitment")
    end

    def impegno_skill_activation_for(domain)
      return if impegno_skill.blank? || domain&.resolved_node.blank?

      impegno_skill.activation_for(domain.resolved_node)
    end

    def current_impegno_skill_activation
      impegno_skill_activation_for(current_domain&.canonical_domain_record)
    end

    def impegno_skill_available_for?(domain)
      impegno_skill.blank? || impegno_skill_activation_for(domain).present?
    end

    def require_current_domain_impegno_skill!
      domain = current_domain&.canonical_domain_record
      return if impegno_skill_available_for?(domain)

      render plain: "La funzione 1Impegno non è attiva per questo Brand.", status: :forbidden
    end
end
