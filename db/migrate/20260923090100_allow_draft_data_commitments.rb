class AllowDraftDataCommitments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :data_commitments, :starts_at, true
  end
end
