class Image < ApplicationRecord

  has_attached_file :image
  belongs_to :report

  # do_not_validate_attachment_file_type :image
  #validates_attachment :image, content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/tif"] }


end
