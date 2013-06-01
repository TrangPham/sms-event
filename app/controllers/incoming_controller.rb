class IncomingController < ApplicationController

  def parse
    Rails.logger.info(params)

    begin
      method, method_params = params["content"].split(" ", 2)
      response = send("call_#{method}".to_sym, params, method_params)
      render json: response
    rescue StandardError
      Rails.logger.info("invalid, try again")
      render nothing: true, status: 200
    end
  end

  private
    def call_hello(params, method_params)
      {"messages" => {"content" => "Goodbye #{method_params}"}}.to_json
    end
end
