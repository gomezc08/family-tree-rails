class DropPeopleTable < ActiveRecord::Migration[8.1]
  def up
    drop_table :people
  end

  def down
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.date :date_died
      t.string :email
      t.string :cell
      t.string :gender
      t.string :cityborn
      t.string :stateborn
      t.string :citycurrent
      t.string :statecurrent

      t.timestamps
    end
  end
end
