class FixColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :reports, :type, :report_type
  end
end
