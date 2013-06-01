class IncomingController < ApplicationController

  def parse
    Rails.logger.info(params)

    begin
      method, method_params = params["content"].split(" ", 2)
      raw = send("call_#{method.downcase}".to_sym, params, method_params)
      render json: sms_response(raw)
    rescue StandardError
      Rails.logger.info("invalid, try again")
      render nothing: true, status: 200
    end
  end

  private

    def response(content)
      {"messages" => [{"content" => content}]}
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
      event = Event.create({:name => method_params, :organizer_phone => params["from_number"]})
      return "Event created, register for event using 'register #{event.event_id}'"
    end

    def call_register(params, method_params)
      user = User.where("phone = ?", params["from_number"])
    end
end
