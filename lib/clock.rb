require 'clockwork'
require 'clockwork/database_events'
require './config/boot'
require './config/environment'

module Clockwork
  # handler receives the time when job is prepared to run in the 2nd argument
  handler do |job, time|
    puts "Running #{job}, at #{time}"
  end

  every(5.seconds, 'frequent.job') { User.delay.first.name }
end
