class CasyncController < ApplicationController

  def configure
    @ca_config = CasyncConfiguration.first
    if !@ca_config
      @ca_config = CasyncConfiguration.new
    end
  end

  def save

  end

  def show
  end
end
