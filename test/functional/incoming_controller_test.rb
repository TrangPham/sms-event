require 'test_helper'

class IncomingControllerTest < ActionController::TestCase

  def setup
    I18n.locale = :en
    @user = User.create({:phone => '5551234'})
  end

  test "invalid command sends error message" do
    post :parse, make_response("garbage")
    assert_response :ok
    assert_equal " ", response.body
  end

  test "help command sends help message" do
    post :parse, make_response("help")
    assert_equal I18n.t("help.help"), text_answer(response)
  end

  test "help command sends help settings message" do
    post :parse, make_response("help settings")

    assert_equal I18n.t("help.settings"), text_answer(response)
  end

  test "create command creates event and returns event id" do
    post :parse, make_response("create")
    @event = assigns(:event)
    assert_equal I18n.t('create.response', { description: @event.description, event_code: @event.event_code }), text_answer(response)
  end

  #
  #  test "register command registers you for event if valid event_id"
  #
  #  test "register returns error if invalid event_id"
  #
  #  test "unregister removes registration"
  #
  #  test "unregister throws error if invalid event_id"
  #
  #  test "cancel cancels event"
  #
  #  test "cancel throws error if invalid event_id"
  #
  #  test "cancel does not cancel event if sender is not organizer"
  #
  #  test "message sends message to all registered users for event_id"
  #
  #  test "message throws error if invalid event_id"
  #
  #  test "message does not send message if sender is nor organizer"
  #
  #  test "info returns info message about event"
  #
  #  test "info throws error if invalid event_id"

  test "settings on should turn on a setting" do
    e = Event.create({:name => "party", :organizer => @user})

    post :parse, make_response("settings #{e.event_code} on talkback")
    e.reload
    assert e.talkback, "event_code #{e.event_code} call_settings returnt #{text_answer(response)}"
  end

  test "message should not broadcast to sender and should include organizer if not from organizer" do
    e = Event.create({:name => "party", :organizer => User.create({:phone => "123456"})})

    post :parse, make_response("settings #{e.event_code} on broadcast", "123456")

    post :parse, make_response("message #{e.event_code} Hello There!")
    assert_equal JSON.parse(response.body), {"messages" => [{"content" => "Message sent: Hello There!"}, {"content" => "#{e.name}(#{e.event_code}): Hello There!", "to_number" => "123456"}]}
  end

  private

  def make_response(message, from = '5551234')
    {
      "event"=>"incoming_message",
      "id"=>"SMfd4d42bf3bf831e70fe35b42661d18d2",
      "message_type"=>"sms",
      "from_number"=> from,
      "phone_id"=>"PN2ef6eed4e19a06d51fd55c22cacc6957",
      "to_number"=>"55512344",
      "contact_id"=>"CT1005f7f6ac2df725a692bc3eed75f5a8",
      "time_created"=>"1370128907",
      "time_sent"=>"1370128903",
      "content"=> message,
      "project_id"=>"PJ1c19e653dc8fb936b724e4dd92915301",
      "secret"=>"2QL37E937PZ4RTDD37AQZNKEWUANDMKF",
      "action"=>"parse",
      "controller"=>"incoming"
    }
  end

  def text_answer(response)
    JSON.parse(response.body)["messages"][0]["content"]
  end
end
