class User < ActiveRecord::Base
  attr_accessible :phone

  validates :phone, uniqueness: true, format: { with: /\A[0-9]{5,}\z/ } 

  has_and_belongs_to_many :events
end
