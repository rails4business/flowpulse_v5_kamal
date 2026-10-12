class RenameMembershipsToBrandAndDomainAccesses < ActiveRecord::Migration[8.1]
  def up
    prepare_domain_nodes!

    rename_table :traveler_subscriptions, :brand_accesses
    rename_column :brand_accesses, :domain_id, :source_domain_id
    rename_column :brand_accesses, :node_id, :brand_node_id
    rename_column :brand_accesses, :subscribed_at, :joined_at

    remove_index :brand_accesses, column: %i[profile_id brand_node_id]
    add_index :brand_accesses, %i[profile_id brand_node_id], unique: true

    rename_table :domain_memberships, :domain_accesses
    rename_column :domain_accesses, :joined_at, :activated_at
    add_reference :domain_accesses, :brand_access, foreign_key: true
    add_column :domain_accesses, :last_accessed_at, :datetime

    execute <<~SQL.squish
      INSERT INTO brand_accesses
        (profile_id, source_domain_id, brand_node_id, status, joined_at, created_at, updated_at)
      SELECT
        domain_accesses.profile_id,
        domain_accesses.domain_id,
        domains.node_id,
        domain_accesses.status,
        domain_accesses.activated_at,
        domain_accesses.created_at,
        domain_accesses.updated_at
      FROM domain_accesses
      INNER JOIN domains ON domains.id = domain_accesses.domain_id
      LEFT JOIN brand_accesses
        ON brand_accesses.profile_id = domain_accesses.profile_id
       AND brand_accesses.brand_node_id = domains.node_id
      WHERE domains.node_id IS NOT NULL
        AND brand_accesses.id IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE domain_accesses
      SET brand_access_id = brand_accesses.id,
          last_accessed_at = domain_accesses.activated_at
      FROM domains, brand_accesses
      WHERE domains.id = domain_accesses.domain_id
        AND brand_accesses.profile_id = domain_accesses.profile_id
        AND brand_accesses.brand_node_id = domains.node_id
    SQL

    orphan_count = select_value("SELECT COUNT(*) FROM domain_accesses WHERE brand_access_id IS NULL").to_i
    if orphan_count.positive?
      raise ActiveRecord::MigrationError,
        "#{orphan_count} DomainAccess non possono essere collegati a un BrandAccess: associa prima i relativi Domain a un Node"
    end

    change_column_null :domain_accesses, :brand_access_id, false
    change_column_null :domain_accesses, :last_accessed_at, false
    add_index :domain_accesses, %i[brand_access_id domain_id], unique: true
  end

  def down
    remove_index :domain_accesses, column: %i[brand_access_id domain_id]
    remove_column :domain_accesses, :last_accessed_at
    remove_reference :domain_accesses, :brand_access, foreign_key: true
    rename_column :domain_accesses, :activated_at, :joined_at
    rename_table :domain_accesses, :domain_memberships

    remove_index :brand_accesses, column: %i[profile_id brand_node_id]
    add_index :brand_accesses, %i[profile_id brand_node_id]
    rename_column :brand_accesses, :joined_at, :subscribed_at
    rename_column :brand_accesses, :brand_node_id, :node_id
    rename_column :brand_accesses, :source_domain_id, :domain_id
    rename_table :brand_accesses, :traveler_subscriptions
  end

  private

    # In produzione alcuni DomainMembership possono essere stati creati prima
    # che config/domains.yml collegasse il relativo Domain al suo Node. Il
    # post-deploy importa la configurazione troppo tardi: db:prepare deve prima
    # riuscire ad avviare il nuovo container. Prepariamo quindi soltanto i
    # cataloghi necessari alla conversione quando esistono davvero record
    # orfani; su un database nuovo questa fase viene saltata.
    def prepare_domain_nodes!
      return unless table_exists?(:domain_memberships)

      orphan_count = select_value(<<~SQL.squish).to_i
        SELECT COUNT(*)
        FROM domain_memberships
        INNER JOIN domains ON domains.id = domain_memberships.domain_id
        WHERE domains.node_id IS NULL
      SQL
      return if orphan_count.zero?

      say_with_time "Associo i Domain esistenti ai Node versionati" do
        NodeCatalog.from_config.import!
        Domain.import_from_config!
      end
    end
end
