class CreateReports < ActiveRecord::Migration[5.1]
  def change
    create_table :reports do |t|
      t.string :type
      t.string :details
      t.integer :likes
      t.datetime :timestamp

      t.timestamps
    end
  end
end
