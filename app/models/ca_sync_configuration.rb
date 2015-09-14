class CaSyncConfiguration < ActiveRecord::Base
  attr_accessible :db_url, :db_user, :db_password, :frequency, :redmine_user_id

  def sync_with_ca
    puts "I'm syncing with CA"
  end

  def name
    return self.class.name
  end

  def at
    return ''
  end
end
