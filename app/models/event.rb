class Event < ActiveRecord::Base
  attr_accessible :event_id, :name, :organizer, :description, :broadcast, :confirm, :notify, :talkback

  validate :event_id, presence: true, uniqueness: true

  before_create :set_event_id
  before_save :default_values
  belongs_to :organizer, :class_name => "User"

  def set_event_id
    _event_id = 0
    while
      _event_id = rand(0..9999)
      break unless Event.find_by_event_id(_event_id)
    end
    self.event_id = _event_id 
  end

  def default_values
    self.broadcast ||= false
    self.confirm ||= false
    self.notify ||= false
    self.talkback ||= false

    true
  end

  has_and_belongs_to_many :users
end
