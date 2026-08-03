class SetPosturacorrettaSharingMetadata < ActiveRecord::Migration[8.1]
  SASSI_IMAGE = "https://ik.imagekit.io/posturacorretta/Sassi-icona-cerchio-bianco.png?updatedAt=1785386494945".freeze

  def up
    execute <<~SQL.squish
      UPDATE domains
      SET settings = (COALESCE(settings::jsonb, '{}'::jsonb) || jsonb_build_object(
        'site_title', 'PosturaCorretta',
        'site_description', 'Trova la giusta posizione da cui osservare il mondo.',
        'favicon_url', '#{SASSI_IMAGE}',
        'social_image_url', '#{SASSI_IMAGE}'
      ))::json
      WHERE hostname = 'posturacorretta.org'
    SQL
  end

  def down
    # I metadati sono dati del brand: non li rimuoviamo automaticamente in rollback.
  end
end
