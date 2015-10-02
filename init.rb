# encoding: UTF-8
require 'redmine'

Redmine::Plugin.register :casync do
  name 'CASync'
  author 'Renan Lage'
  description 'This is a plugin for Redmine integration with the CA HelpDesk'
  version '0.0.1'

  permission :casync_permission, { :casync => [:show] }, :require => :loggedin

  menu :top_menu, :casync,
       { :controller => 'casync', :action => 'index' },
       :after => :projects,
       :caption => 'CASync',
       :if => Proc.new{ User.current.logged? }

  settings :default => {
                        'active' => false,
                       },
           :partial => 'settings/configure'
end
