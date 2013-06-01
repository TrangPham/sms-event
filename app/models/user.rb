class User < ActiveRecord::Base
  attr_accessible :phone

  validates :phone, uniqueness: true 

  has_many :events, through: :event_users
end
