class Report < ApplicationRecord

  belongs_to :bike_path
  belongs_to :user
  belongs_to :location
  has_one :image

  before_update :check_likes

  accepts_nested_attributes_for :bike_path, :user, :location, :image

  private

    def check_likes
      # Increment likes by 1, no matter what the front-end thinks the new number of likes is.
      if self.changes.include?('likes')
        self.likes = self.changed_attributes[:likes] + 1 #changed_attributes is the original value before change
      end
    end
end
