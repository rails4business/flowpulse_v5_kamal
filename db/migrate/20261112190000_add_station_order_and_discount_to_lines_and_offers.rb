class AddStationOrderAndDiscountToLinesAndOffers < ActiveRecord::Migration[8.1]
  def change
    add_column :metro_lines, :station_node_ids, :bigint, array: true, default: [], null: false
    add_column :offers, :discount_percent, :decimal, precision: 5, scale: 2
  end
end
