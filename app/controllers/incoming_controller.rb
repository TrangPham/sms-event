class IncomingController < ApplicationController

  def parse
    Rails.logger.info(params)

    begin
      method, method_params = params["content"].split(" ", 2)
      raw = send("call_#{method}".to_sym, params, method_params)
      render json: response(raw)
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
      {"messages" => [{"content" => "Goodbye #{method_params}"}]}.to_json
    end

    def call_help(params, method_params)
      case method_params
      when nil
        return "Help text goes here"
      when "register"
        return "Register help text"
      end
    end

    def call_create(params, method_params)
      event  = Event.create({:name => method_params})
      return "Event created, register for event using 'register #{event.event_id}'"
    end
end
