class CreateBrandRequests < ActiveRecord::Migration[8.1]
  def up
    create_table :brand_requests do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :brand_node, null: false, foreign_key: { to_table: :nodes }
      t.references :requester_profile, foreign_key: { to_table: :profiles }
      t.references :participant_contact, foreign_key: { to_table: :impegno_contacts }
      t.references :assigned_to_profile, foreign_key: { to_table: :profiles }
      t.references :subject, polymorphic: true
      t.string :kind, null: false
      t.string :audience, null: false, default: "user"
      t.string :status, null: false, default: "open"
      t.string :title, null: false
      t.text :message
      t.string :source_url
      t.jsonb :metadata, null: false, default: {}
      t.datetime :resolved_at
      t.bigint :legacy_data_commitment_id
      t.timestamps
    end

    add_index :brand_requests, %i[brand_node_id status]
    add_index :brand_requests, %i[domain_id kind status]
    add_index :brand_requests, %i[subject_type subject_id]
    add_index :brand_requests, :legacy_data_commitment_id, unique: true
    add_foreign_key :brand_requests, :data_commitments, column: :legacy_data_commitment_id

    add_reference :brand_invitations, :brand_request, foreign_key: true
    add_reference :data_commitments, :brand_request, foreign_key: true

    # Conserva le richieste esterne già registrate come DataCommitment. I record
    # originali restano disponibili durante la transizione e vengono esclusi
    # dalla nuova vista degli impegni tramite legacy_data_commitment_id.
    execute <<~SQL
      INSERT INTO brand_requests (
        domain_id, brand_node_id, participant_contact_id,
        subject_type, subject_id, kind, audience, status,
        title, message, source_url, metadata, resolved_at,
        legacy_data_commitment_id, created_at, updated_at
      )
      SELECT
        dc.domain_id,
        domains.node_id,
        dc.participant_contact_id,
        dc.subject_type,
        dc.subject_id,
        CASE dc.metadata ->> 'request_kind'
          WHEN 'access_invitation' THEN 'access'
          ELSE COALESCE(NULLIF(dc.metadata ->> 'request_kind', ''), 'other')
        END,
        COALESCE(NULLIF(dc.metadata ->> 'request_audience', ''), 'user'),
        CASE dc.status
          WHEN 'requested' THEN 'open'
          WHEN 'in_progress' THEN 'in_progress'
          WHEN 'planned' THEN 'waiting'
          WHEN 'confirmed' THEN 'waiting'
          WHEN 'completed' THEN 'closed'
          WHEN 'cancelled' THEN 'cancelled'
          ELSE 'open'
        END,
        dc.title,
        dc.description,
        dc.metadata ->> 'source_url',
        dc.metadata - 'request_kind' - 'request_audience' - 'source_url',
        dc.resolved_at,
        dc.id,
        dc.created_at,
        dc.updated_at
      FROM data_commitments dc
      INNER JOIN domains ON domains.id = dc.domain_id
      WHERE dc.participant_contact_id IS NOT NULL
        AND dc.blocks_calendar = FALSE
        AND dc.metadata ? 'request_kind'
        AND domains.node_id IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE brand_invitations invitations
      SET brand_request_id = requests.id
      FROM brand_requests requests
      INNER JOIN data_commitments commitments
        ON commitments.id = requests.legacy_data_commitment_id
      WHERE commitments.metadata ->> 'brand_invitation_id' = invitations.id::text
    SQL
  end

  def down
    remove_reference :data_commitments, :brand_request, foreign_key: true
    remove_reference :brand_invitations, :brand_request, foreign_key: true
    drop_table :brand_requests
  end
end
