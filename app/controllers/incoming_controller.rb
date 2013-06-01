class IncomingController < ApplicationController

  def parse
    Rails.logger.info(params)

    begin
      method, method_params = params["content"].split(" ", 2)
      content, more = send("call_#{method.downcase}".to_sym, params, method_params)
      render json: sms_response(content, more)
    rescue StandardError
      Rails.logger.info("invalid, try again")
      render nothing: true, status: 200
    end
  end

  private

    def sms_response(content, more = [])  
      to_return = {"messages" => [{"content" => content}]}
      more.each{|m| to_return["messages"] << m}
      to_return
    end

    def call_hello(params, method_params)
      "Goodbye #{method_params}"
    end

    def call_help(params, method_params)
      case method_params
      when nil
        return "Available commands: register, create, unregister, message, status. Send 'help COMMAND' for more info"
      when "register"
        return "Register help text"
      when "create"
        return "create [event name]"
      else
        return "Sorry, #{method_params} is not a command"
      end
    end

    def call_create(params, method_params)
      event = Event.create({:name => method_params, :organizer => User.find_or_create_by_phone({:phone=> params["from_number"]})})
      return "Event created, register for event using 'register #{event.event_id}'"
    end

    def call_register(params, method_params)
      user = User.find_or_create_by_phone({:phone=> params["from_number"]})
      event = Event.find_by_event_id(method_params)
      event.users << user unless event.users.exists?(user)
      return "You have registered for event: #{event.event_id} #{event.name}"
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
      return "Event #{event_id} does not exists" if event.nil? 

      if event.organizer.phone == params["from_number"]
        more = []
        event.users.each do |user| 
          more << {"content" => msg, "to_number" => user.phone.to_s}
        end
        return "Message sent: #{msg}", more
      else
        return "Only the event organizer can message the attendees"
      end
    end

    def call_status(params, method_params)
    end
end
