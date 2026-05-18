class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.string :hostname, null: false
      t.string :canonical_host
      t.string :locale, null: false, default: "it"
      t.string :action, null: false, default: "mvp_home"
      t.text :html_home
      t.boolean :primary, null: false, default: false
      t.boolean :active, null: false, default: true
      t.json :settings

      t.timestamps
    end

    add_index :domains, :hostname, unique: true
  end
end
