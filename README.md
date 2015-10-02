CASync
============

This is a Redmine plugin that integrates Redmine with the HelpDesk software CA

Installation
============
CASync only supports Rails 3.0+, Ruby 2.0+ and Redmine 2.5+

First copy the 'casync' folder to your plugins directory in Redmine "#REDMINE-ROOT/plugins/"

Then on your Redmine root directory execute the commands:

```
bundle install
rails g delayed_job:active_record
rake db:migrate
rake redmine:plugins:migrate RAILS_ENV=production
```

Usage
============

To run Redmine with CASync run the following commands
```
bundle exec rails server &
bundle exec rake jobs:work &
bundle exec clockwork plugins/casync/lib/clock.rb
```
