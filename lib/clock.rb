require 'clockwork'
require 'clockwork/database_events'
require './config/boot'
require './config/environment'

module Clockwork

  # required to enable database syncing support
  Clockwork.manager = DatabaseEvents::Manager.new

  # Check if there is already a CasyncConfiguration table present and create it otherwise with a high frequency
  unless CasyncConfiguration.any?
    CasyncConfiguration.create(:frequency => 1000000000)
  end

  sync_database_events :model => CasyncConfiguration,
                       :every => 30.seconds,
                       :if => Setting.where(:name => 'plugin_casync').first.value['active'] == 'true' do |model_instance|

    if Setting.where(:name => 'plugin_casync').first.value['active'] == 'true'
      model_instance.delay.sync_with_ca
    end

  end
end
