class User < ActiveRecord::Base
  attr_accessible :phone

  validates :phone, uniqueness: true 

  has_and_belongs_to_many :events
end
