class AddInitiatedByToRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :relationships, :initiated_by_id, :integer
    add_index :relationships, :initiated_by_id
    add_foreign_key :relationships, :users, column: :initiated_by_id

    # Backfill existing relationships: set initiated_by_id to user_id
    # This assumes the user_id is the person who created the relationship
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE relationships
          SET initiated_by_id = user_id
          WHERE initiated_by_id IS NULL
        SQL
      end
    end
  end
end
