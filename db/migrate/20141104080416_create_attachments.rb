class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :sha2, null: false
      t.binary :content, null: false, limit: 2 ** 24 - 1

      t.timestamps
    end

    add_index :attachments, :sha2, unique: true
  end
end
