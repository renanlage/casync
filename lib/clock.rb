require 'clockwork'
require 'clockwork/database_events'
require './config/boot'
require './config/environment'

module Clockwork

  # required to enable database syncing support
  Clockwork.manager = DatabaseEvents::Manager.new

  sync_database_events :model => CasyncConfiguration, :every => 1.minute do |model_instance|

    CasyncConfiguration.delay.sync_with_ca

  end
end
