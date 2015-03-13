class CreateStatements < ActiveRecord::Migration
  def change
    create_table :statements do |t|
      t.string :user_uid, null: false
      t.string :service_uid, null: false
      t.text :json_statement, null: false

      t.timestamps
    end

    add_index :statements, :user_uid
    add_index :statements, :service_uid
  end
end
