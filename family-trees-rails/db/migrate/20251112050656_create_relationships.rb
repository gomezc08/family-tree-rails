class CreateRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :relationships do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.references :relative, null: false, foreign_key: { to_table: :users }
      t.string :relationship_type, null: false
      t.date :start_date
      t.date :end_date
      t.text :notes

      t.timestamps
    end

    # Add indexes for efficient querying
    add_index :relationships, [:user_id, :relative_id, :relationship_type],
              name: 'index_relationships_on_user_relative_type'
    add_index :relationships, [:relative_id, :user_id],
              name: 'index_relationships_on_relative_user'
  end
end
