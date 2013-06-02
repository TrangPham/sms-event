class Registration < ActiveRecord::Base
  attr_accessible :event_id, :user_id, :register_code, :confirmed

  validate :event_id, presence: true
  validate :user_id, presence: true

  before_create :set_register_code
  before_save :default_values

  def set_register_code
    _register_code = 0
    while
      _register_code = rand(0..9999)
      break unless Registration.find_by_register_code(_register_code)
    end
    self.register_code = _register_code 
  end

  def default_values
    self.confirmed ||= !Event.find(event_id).confirm
  
    true
  end

  belongs_to :user
  belongs_to :event
end