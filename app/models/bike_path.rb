class BikePath < ApplicationRecord

  has_many :locations
  has_many :reports

end
