class Removeimageidfromreports < ActiveRecord::Migration[5.1]
  def change
    remove_column :reports, :image_id
  end
end
