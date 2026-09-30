class RenameBrandProcessesToNodeProcesses < ActiveRecord::Migration[8.1]
  def change
    rename_table :brand_processes, :node_processes
    rename_column :data_experiences, :brand_process_id, :node_process_id
  end
end
