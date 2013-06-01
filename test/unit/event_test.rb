require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "random id is created" do
    assert_difference 'Event.count' do
      event = Event.create(name: 'test')
      assert event.valid?
      assert event.event_id 
    end
  end
end
