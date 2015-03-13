class CreateAttachmentRelations < ActiveRecord::Migration
  def change
    create_table :attachment_relations do |t|
      t.references :statement, null: false
      t.references :attachment, null: false

      t.timestamps
    end

    add_index :attachment_relations, [:statement_id, :attachment_id], unique: true
  end
end
