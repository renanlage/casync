require 'clockwork'
require 'clockwork/database_events'
require './config/boot'
require './config/environment'

module Clockwork

  # required to enable database syncing support
  Clockwork.manager = DatabaseEvents::Manager.new

  sync_database_events :model => CaSyncConfiguration, :every => 1.minute do |model_instance|

    model_instance.delay.sync_with_ca

  end
end
