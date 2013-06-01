class Event < ActiveRecord::Base
  attr_accessible :event_id, :name

  validate :name, presence: true, uniqueness: true

  before_create :set_event_id

  def set_event_id
    _event_id = 0
    while
      _event_id = rand(0..9999)
      break unless Event.find_by_event_id(_event_id)
    end
    self.event_id = _event_id 
  end

  has_many :users, through: :event_users

end
