class Report < ApplicationRecord

  belongs_to :bike_path
  belongs_to :user
  belongs_to :location

  accepts_nested_attributes_for :bike_path, :user, :location

end
