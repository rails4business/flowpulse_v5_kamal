class AddDataSlotToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_reference :data_commitments, :data_slot, foreign_key: true
    add_index :data_commitments, %i[data_slot_id status]
  end
end
