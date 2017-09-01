class CreateLocations < ActiveRecord::Migration[5.1]
  def change
    create_table :locations do |t|
      t.decimal :lat
      t.decimal :long
      t.text :name

      t.timestamps
    end
  end
end
