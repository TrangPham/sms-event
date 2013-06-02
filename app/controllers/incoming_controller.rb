class IncomingController < ApplicationController

  VALID_SETTINGS = ["talkback", "broadcast", "notify", "confirm"]

  VALID_COMMANDS = {
    "register" => "register [event id]",
    "help" => "Available commands: register, create, unregister, message, status. Send 'help COMMAND' for more info",
    "unregister" => "Usage: 'unregister [event id]'",
    "create" => "create [event name], [event info]",
    "message" => "message [event id] [message]",
    "cancel" => "cancel [event id]",
    "info" => "info [event id]",
    "settings" => "Usage: 'settings [toggle | on | off] [list]' Available Settings: #{VALID_SETTINGS}"
  }

  def parse
    Rails.logger.info(params)

    method, method_params = params["content"].split(" ", 2)
    if VALID_COMMANDS.keys.include?(method.downcase)
      content, more = send("call_#{method.downcase}".to_sym, params, method_params)
      render json: sms_response(content, more)
    else
      Rails.logger.info("invalid, try again")
      render nothing: true, status: 200
    end
  end

  private

  def call_settings(params, method_params)
    event_id = method_params[0]
    event = Event.find_by_event_id(event_id)
    return "Event #{event_id} does not exist" if event.nil? 

    return "Only event organizer can change settings" unless event.organizer.phone == params["from_number"]
    list = method_params.split(" ")
    mode = list.shift
    list.each do |setting|
      case mode
      when "toggle"
        event.send("#{setting}=".to_sym, !event.setting)
      when "on"
        event.send("#{setting}=".to_sym, true)
      when "off"
        event.send("#{setting}=".to_sym, false)
      else
      end
    return "Settings updated"
  end

  def sms_response(content, more)  
    more ||= []
    to_return = {"messages" => [{"content" => content}]}
    more.each{|m| to_return["messages"] << m}
    to_return
  end

  def call_help(params, method_params)
    return VALID_COMMANDS["help"] if method_params.blank?
    return if VALID_COMMANDS.keys.include?(method_params) ? VALID_COMMANDS[method_params] : "Sorry, #{method_params} is not a valid command"
  end

  def call_create(params, method_params)
    name, info = method_params.split(",", 2)
    event = Event.create({:name => name.strip,
                         :organizer => User.find_or_create_by_phone({:phone=> params["from_number"]}),
                         :description => info.strip 
    })
    return "Event #{event.name} created, register for event using 'register #{event.event_id}'"
  end

  def call_update(params, method_params)
    event_id, info = method_params.split(",", 2)
    event = Event.find_by_event_id(event_id)
    return "Event #{method_params} does not exist" if event.nil?

    event.description =  info.strip
    event.save
    return "Event #{event.name} was updated"
  end

  def call_cancel(params, method_params)
    event = Event.find_by_event_id(method_params)
    return "Event #{method_params} does not exist" if event.nil?

    msg = "Event #{event.name}(#{method_params}) was cancelled"
    event.description = msg
    event.save
    if event.organizer.phone == params["from_number"]
      more = []
      event.users.each do |user| 
        more << {"content" => msg, "to_number" => user.phone}
      end
      return msg, more
    else
      return "Only the event organizer can cancel the event"
    end
  end

  def call_register(params, method_params)
    user = User.find_or_create_by_phone({:phone=> params["from_number"]})
    event = Event.find_by_event_id(method_params)
    more = nil
    unless event.users.exists?(user)
      event.users << user 
      more = [{"content" => "A user has registered. Total Registered: #{event.users.count}", "to_number" => event.organizer.phone}] if event.notify
    end
    return "Registered: #{event.name}(#{event.event_id}) Info: #{event.description}", more
  end

  def call_unregister(params, method_params)
    user = User.find_or_create_by_phone({:phone=> params["from_number"]})
    event = Event.find_by_event_id(method_params)
    event.users.delete(user)
    return "You have unregistered from event: #{event.event_id} #{event.name}"
  end

  def call_message(params, method_params)
    event_id, msg = method_params.split(" ", 2)
    event = Event.find_by_event_id(event_id)
    return "Event #{event_id} does not exist" if event.nil? 

    if event.broadcast or event.organizer.phone == params["from_number"]
      more = []
      event.users.each do |user| 
        more << {"content" => "#{event.name}(#{event.id}): #{msg}", "to_number" => user.phone.to_s}
      end
      return "Message sent: #{msg}", more
    else
      return "Only the event organizer can message the attendees"
    end
  end

  def call_info(params, method_params)
    event = Event.find_by_event_id(method_params)
    return "Event #{event_id} does not exist" if event.nil? 

    return  "ID: #{event.name}(#{event.event_id}) Registered: #{event.users.count} Info: #{event.description}"    

  end

end
