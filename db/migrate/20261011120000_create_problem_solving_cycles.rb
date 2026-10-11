class CreateProblemSolvingCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :problem_solving_cycles do |t|
      t.references :owner_profile, null: false, foreign_key: { to_table: :profiles }
      t.references :responsible_profile, null: true, foreign_key: { to_table: :profiles }
      t.string :title, null: false
      t.text :problem
      t.text :isolated_problem
      t.text :possible_solutions
      t.text :minimum_solution
      t.text :self_test
      t.text :small_group_test
      t.text :feedback
      t.text :validation_notes
      t.text :diffusion_notes
      t.text :closure_notes
      t.string :status, null: false, default: "backlog"
      t.integer :current_step, null: false, default: 0
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :problem_solving_cycles, :status
    add_index :problem_solving_cycles, :owner_profile_id,
      unique: true,
      where: "status = 'active'",
      name: "index_one_active_problem_cycle_per_profile"

    create_table :problem_solving_cycle_nodes do |t|
      t.references :problem_solving_cycle, null: false, foreign_key: true
      t.references :node, null: false, foreign_key: true
      t.timestamps
    end

    add_index :problem_solving_cycle_nodes,
      %i[problem_solving_cycle_id node_id],
      unique: true,
      name: "index_problem_cycles_nodes_uniqueness"
  end
end
