# Collega ai Content gli impegni che hanno solo content_key: quelli nati prima di Content, oppure tutti
# dopo che il database è stato ricostruito dai YAML. Non inventa: un impegno senza un Content unico resta
# scollegato e viene segnalato. Il collegamento serve alla storia: gli impegni non cambiano più lo stato
# di pubblicazione dei Content.
class ContentCommitmentLinks
  Result = Data.define(:linked, :missing)

  def link!(dry_run: false)
    result = nil

    ActiveRecord::Base.transaction do
      linked = 0
      missing = []

      DataCommitment.where.not(content_key: [nil, ""]).where(content_id: nil).find_each do |commitment|
        content = commitment.matching_content
        unless content
          missing << "impegno #{commitment.id} (#{commitment.kind}): #{commitment.content_key}"
          next
        end

        commitment.update_columns(content_id: content.id)
        linked += 1
      end

      result = Result.new(linked:, missing:)
      raise ActiveRecord::Rollback if dry_run
    end

    result
  end
end
