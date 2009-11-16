##
# A session controls access for a user
#
class Session < ActiveRecord::Base

  belongs_to :user

end
