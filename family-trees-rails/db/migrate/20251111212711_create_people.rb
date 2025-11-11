class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.date :birthday
      t.date :date_died
      t.string :gender
      t.string :email
      t.string :cell
      t.string :cityborn
      t.string :stateborn
      t.string :citycurrent
      t.string :statecurrent

      t.timestamps
    end
  end
end
