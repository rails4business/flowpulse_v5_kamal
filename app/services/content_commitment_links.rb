# Collega ai Content gli impegni che hanno solo content_key: quelli nati prima di Content, oppure tutti
# dopo che il database è stato ricostruito dai YAML. Non inventa: un impegno senza un Content unico resta
# scollegato e viene segnalato.
#
# Per i Content appena collegati riapplica in ordine le decisioni di pubblicazione concluse, così il loro
# stato è quello dell'ultima decisione, come se gli impegni fossero stati conclusi dopo l'import.
class ContentCommitmentLinks
  Result = Data.define(:linked, :missing, :replayed)

  def link!(dry_run: false)
    result = nil

    ActiveRecord::Base.transaction do
      linked = 0
      missing = []
      content_ids = Set.new

      DataCommitment.where.not(content_key: [nil, ""]).where(content_id: nil).find_each do |commitment|
        content = commitment.matching_content
        unless content
          missing << "impegno #{commitment.id} (#{commitment.kind}): #{commitment.content_key}"
          next
        end

        commitment.update_columns(content_id: content.id)
        linked += 1
        content_ids << content.id
      end

      result = Result.new(linked:, missing:, replayed: replay!(content_ids))
      raise ActiveRecord::Rollback if dry_run
    end

    result
  end

  private

    def replay!(content_ids)
      Content.where(id: content_ids.to_a).sum(&:replay_publication_decisions!)
    end
end
