class AddParticipantContactToDataCommitments < ActiveRecord::Migration[8.1]
  def change
    add_reference :data_commitments,
                  :participant_contact,
                  foreign_key: { to_table: :impegno_contacts },
                  index: true
  end
end
