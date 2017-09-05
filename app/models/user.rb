class User < ApplicationRecord

has_many :reports
has_secure_password validations: false

end
