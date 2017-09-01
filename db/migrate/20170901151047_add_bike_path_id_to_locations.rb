class AddBikePathIdToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :bike_path_id, :integer
  end
end
