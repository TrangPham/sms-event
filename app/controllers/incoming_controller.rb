class IncomingController < ApplicationController

  VALID_SETTINGS = ["talkback", "broadcast", "notify", "confirm"]

  VALID_COMMANDS = ["register", "help", "unregister", "create", "message", "cancel", "info", "settings", "confirm", "reply"]

  def parse
    Rails.logger.info(params)

    command, method_params = params["content"].split(" ", 2)
    if t('commands').values.include?(command.downcase)
      method = t('commands').invert[command.downcase]
      content, more = send("call_#{method}".to_sym, params, method_params)
      render json: sms_response(content, more)
    else
      Rails.logger.info("invalid, try again")
      render nothing: true, status: 200
    end
  end

  private

  def call_confirm(params, method_params)
    reg = Registration.find_by_register_code(method_params)
    return "#{method_params} is not a valid registration code" if reg.nil?

    reg.confirmed = true
    reg.save
    return "#{reg.user.name} has been confirmed. They will now recieve event messages.", [{"content" => "Registration confirmed: #{event.name}(#{event.event_code}) Info: #{event.description}", "to_number" => reg.user.phone}]
  end

  def call_talkback(params, method_params)
    event_code, msg = method_params.split(" ", 2)
    event = Event.find_by_event_code(event_code)
    return "Event #{event_code} does not exist" if event.nil? 
    return "Event organizer has opted not to recieve messages from attendees." unless event.talkback

    return "Message sent to organizer.", [{"content" => msg, "to_number" => event.organizer.phone}]
  end

  def call_settings(params, method_params)
    list = method_params.split(" ")
    event_code = list.shift
    event = Event.find_by_event_code(event_code)
    return "Event #{event_code} does not exist" if event.nil? 

    return "Only event organizer can change settings" unless event.organizer.phone == params["from_number"]

    mode = list.shift
    list = VALID_SETTINGS if mode == "show"
    msg = "Settings #{event.event_code}:"
    list.each do |setting|
      setting.strip!
      case mode
      when "toggle"
        event.send("#{setting}=".to_sym, !event.setting)
      when "on"
        event.send("#{setting}=".to_sym, true)
      when "off"
        event.send("#{setting}=".to_sym, false)        
      end
      event.save
      msg += " #{setting}"
      msg += event.send("#{setting}".to_sym) ? " on," : " off," 
    end
    return msg
  end

  def sms_response(content, more)  
    more ||= []
    to_return = {"messages" => [{"content" => content}]}
    more.each{|m| to_return["messages"] << m}
    to_return
  end

  def call_help(params, method_params)
    return t("help.help") if method_params.blank?
    return t("help").keys.include?(method_params.to_sym) ? t("help.#{method_params}") : "#{method_params} #{t('errors.invalid_help')}"
  end

  def call_create(params, method_params)
    method_params ||= ""
    name, info = method_params.split(",", 2)
    name.strip! if name
    info.strip! if info
    @event = Event.create({:name => name,
                         :organizer => User.find_or_create_by_phone({:phone=> params["from_number"]}),
                         :description => info
    })
    return t('create.response', { description: @event.description, event_code: @event.event_code })
  end

  def call_update(params, method_params)
    event_code, info = method_params.split(",", 2)
    event = Event.find_by_event_code(event_code)
    return "Event #{method_params} does not exist" if event.nil?

    event.description =  info.strip
    event.save
    return "Event #{event.name} was updated"
  end

  def call_cancel(params, method_params)
    event = Event.find_by_event_code(method_params)
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
    event = Event.find_by_event_code(method_params)
    more = nil
    unless event.users.exists?(user)
      event.users << user 
      r = Registration.find.where({:user => user, :event => event})
      msg = "User #{user.name} wants to register. Text 'confirm #{r.register_code}' to confirm" if event.confirm
      msg ||= "User #{user.name} has registered. Total Registered: #{event.users.count}" if event.notify
      more = [{"content" => msg, "to_number" => event.organizer.phone}] unless msg.blank?
    end
    msg = "You will recieve a notification when the organizer has confirmed your registration." if event.confirm
    msg ||= "Registered: #{event.name}(#{event.event_code}) Info: #{event.description}"
    return msg, more
  end

  def call_unregister(params, method_params)
    user = User.find_or_create_by_phone({:phone=> params["from_number"]})
    event = Event.find_by_event_code(method_params)
    event.users.delete(user)
    return "You have unregistered from event: #{event.event_code} #{event.name}"
  end

  def call_message(params, method_params)
    event_code, msg = method_params.split(" ", 2)
    event = Event.find_by_event_code(event_code)
    return "Event #{event_code} does not exist" if event.nil? 

    if event.broadcast or event.organizer.phone == params["from_number"]
      more = []
      event.users.each do |user| 
        more << {"content" => "#{event.name}(#{event.event_code}): #{msg}", "to_number" => user.phone.to_s}
      end
      return "Message sent: #{msg}", more
    else
      return "Only the event organizer can message the attendees"
    end
  end

  def call_info(params, method_params)
    event = Event.find_by_event_code(method_params)
    return "Event #{method_params} does not exist" if event.nil? 
    return  "Name:  #{event.name}(#{event.event_code}) Registered: #{event.users.count} Info: #{event.description}"    
  end

end
