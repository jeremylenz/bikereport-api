class Location < ApplicationRecord

  has_many :reports
  belongs_to :bike_path

  accepts_nested_attributes_for :bike_path

end
