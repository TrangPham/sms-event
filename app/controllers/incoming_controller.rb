class IncomingController < ApplicationController

  def parse
    Rails.logger.info(params)
    render nothing: true, status: 200
  end
end
