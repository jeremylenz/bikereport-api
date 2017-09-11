class AddReportIdToImages < ActiveRecord::Migration[5.1]
  def change
    add_column :images, :report_id, :integer
  end
end
