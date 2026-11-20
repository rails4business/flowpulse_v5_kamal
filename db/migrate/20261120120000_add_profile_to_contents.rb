# Profilo titolare del Content: distinto dagli autori (ContentContribution), decide chi lo gestisce anche
# dall'admin del proprio brand quando il Content sta in un altro brand.
class AddProfileToContents < ActiveRecord::Migration[8.1]
  def change
    add_reference :contents, :profile, foreign_key: true
  end
end
