# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'casync', :to => 'ca_sync#show'
get 'casync/configure', :to => 'ca_sync#configure'
