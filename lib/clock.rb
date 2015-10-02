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
                       :every => 30.seconds do |model_instance|

    setting = Setting.where(:name => 'plugin_casync').first
    if !setting.nil? && setting.value['active'] == 'true'
      model_instance.delay.sync_with_ca
      CasyncInstance.create.delay.sync_with_ca(model_instance)
    end

  end
end
