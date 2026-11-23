class PrepareNodeCourseLines < ActiveRecord::Migration[8.1]
  def up
    add_reference :offers, :line_node, foreign_key: { to_table: :nodes }, index: true
    change_column_null :offers, :metro_line_id, true

    Posturacorretta::CourseLineCatalog.new.sync! if Node.exists?(slug: "posturacorretta")

    line_by_offer = {
      "prima-settimana-posturacorretta" => "inizia-con-posturacorretta",
      "igiene-posturale" => "area-massaggio-terapie-manuali-tecniche-corporee",
      "area-massaggio-recupero" => "area-massaggio-terapie-manuali-tecniche-corporee"
    }
    line_by_offer.each do |offer_slug, line_slug|
      Offer.where(slug: offer_slug).update_all(line_node_id: Node.find_by!(slug: line_slug).id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Le offerte senza MetroLine non possono essere ripristinate" if Offer.where(metro_line_id: nil).exists?

    change_column_null :offers, :metro_line_id, false
    remove_reference :offers, :line_node, foreign_key: true
  end
end
