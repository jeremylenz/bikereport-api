class RemoveTimestampFromReports < ActiveRecord::Migration[5.1]
  def change
    remove_column :reports, :timestamp
  end
end
