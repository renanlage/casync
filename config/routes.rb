# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'casync', :to => 'casync#show'
get 'casync/configure', :to => 'casync#configure'
match 'casync/configure', :to => 'casync#save', :via => [:put, :post]

