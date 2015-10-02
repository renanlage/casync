class CasyncConfiguration < ActiveRecord::Base
  attr_accessible :db_user, :db_password, :db_url, :redmine_user_id, :frequency, :active

  def sync_with_ca
    sync_settings
  end

  def sync_settings
    self.db_url = Setting['plugin_casync']['db_url'] if self.db_url != Setting['plugin_casync']['db_url']
    self.db_user = Setting['plugin_casync']['db_user'] if self.db_user != Setting['plugin_casync']['db_user']
    self.db_password = Setting['plugin_casync']['db_password'] if self.db_password != Setting['plugin_casync']['db_password']
    self.frequency = Setting['plugin_casync']['frequency'] if self.frequency != Setting['plugin_casync']['frequency']
    self.redmine_user_id = Setting['plugin_casync']['redmine_user_id'] if self.redmine_user_id != Setting['plugin_casync']['redmine_user_id']
    active = Setting['plugin_casync']['active'] == 'true'
    self.active = active if self.active != active
    save if changed?
  end

  def name
    return self.class.name
  end

  def at
    return ''
  end
end
