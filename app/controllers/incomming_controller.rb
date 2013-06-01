class IncommingController < ApplicationController

  def parse
    Rails.logger.info(params)

    method, method_params = params["content"].split(" ", 2)
    begin
      object.send("call_#{method}".to_sym, params, method_params)
    rescue

    end


  end

  private
    def call_hello(params, method_params)
      {"messages" => {"content" => "Goodbye #{method_params}"}}.to_json
    end
end
