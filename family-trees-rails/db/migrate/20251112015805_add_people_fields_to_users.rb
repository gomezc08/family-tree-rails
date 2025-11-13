class AddPeopleFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :birthday, :date
    add_column :users, :date_died, :date
    add_column :users, :cell, :string
    add_column :users, :gender, :string
    add_column :users, :cityborn, :string
    add_column :users, :stateborn, :string
    add_column :users, :citycurrent, :string
    add_column :users, :statecurrent, :string
  end
end
