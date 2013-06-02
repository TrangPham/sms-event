class User < ActiveRecord::Base
  attr_accessible :phone, :name

  validates :phone, uniqueness: true, format: { with: /\A[0-9]{5,}\z/ } 

  has_many :registrations
  has_many :events, :through => :registrations
end
