class IncommingController < ApplicationController

  def parse
    Rails.logger.info(params)
  end
end
