class AddForeignKeystoReports < ActiveRecord::Migration[5.1]
  def change
      add_column :reports, :bike_path_id, :integer
      add_column :reports, :user_id, :integer
      add_column :reports, :location_id, :integer
  end
end
