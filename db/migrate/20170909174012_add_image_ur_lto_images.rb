class AddImageUrLtoImages < ActiveRecord::Migration[5.1]
  def change
    add_column :images, :image_url, :string
  end
end
