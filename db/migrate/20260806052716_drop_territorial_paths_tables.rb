class DropTerritorialPathsTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :posturacorretta_territorial_path_participants
    drop_table :posturacorretta_territorial_paths
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
