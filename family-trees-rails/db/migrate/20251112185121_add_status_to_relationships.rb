class AddStatusToRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :relationships, :status, :string, default: 'pending', null: false
    add_index :relationships, :status
  end
end
