class Event < ActiveRecord::Base
  attr_accessible :event_code, :name, :organizer, :description, :broadcast, :confirm, :notify, :talkback

  validate :event_code, presence: true, uniqueness: true

  before_create :set_event_code
  before_save :default_values
  belongs_to :organizer, :class_name => "User"

  def set_event_code
    _event_code = 0
    while
      _event_code = rand(0..9999)
      break unless Event.find_by_event_code(_event_code)
    end
    self.event_code = _event_code 
  end

  def default_values
    self.broadcast ||= false
    self.confirm ||= false
    self.notify ||= false
    self.talkback ||= false
    self.description ||= "no description"
    self.name ||= "no name"
    true
  end

  has_many :registrations
  has_many :users, :through => :registrations
end
