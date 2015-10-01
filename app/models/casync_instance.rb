class CasyncInstance < ActiveRecord::Base
  attr_accessible :created_on, :succeeded, :message, :n_calls_inserted, :n_calls_updated, :calls_inserted, :calls_updated
end
