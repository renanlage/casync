require 'oci8'

class CasyncConfiguration < ActiveRecord::Base
  attr_accessible :frequency, :active

  def sync_with_ca()
    # Update class attributes with Settings values
    sync_settings

    # Read query from file and customize it
    query = File.read('plugins/casync/query.sql')
    mod_query = customize_query(query)

    # Connect to database and execute modified query
    conn = OCI8.new(self.db_user, self.db_password, self.db_url)
    result = conn.exec(mod_query)
  end

  # Receives a query and change it to lookup for all 'ArvoreSistemas' defined in projects
  def customize_query(query)
    # Query to find all projects with HabilitarCASync field set to true
    projects = Project.where(:id => CustomField.where(:name => 'HabilitarCaSync').first.custom_values.where(:value => 1).select(:customized_id))

    # Query to find ArvoreSistemas field of project with CASync enabled
    arvores_values = CustomField.where(:name => 'ArvoreSistemas').first.custom_values.where(:customized_id => projects).select(:value)
    or_value = "            OR\n"

    # Find query line to be customized
    custom_line = ''
    query.each_line do |line|
      if line['#arvoresistema#']
        custom_line = line
        break
      end
    end

    # Loop through arvores names and add custom lines with them
    insert_index = query.index(custom_line) + custom_line.length
    arvores_values.each_with_index do |arvore, index|

      mod_line = custom_line.gsub('#arvoresistema#', arvore.value)

      if index == 0
        query.gsub!(custom_line, mod_line)
        insert_index = query.index(mod_line) + mod_line.length
      else
        # Insert OR statement to query
        query.insert insert_index, or_value
        old_index = insert_index
        insert_index += or_value.length

        # Insert modified query line
        query.insert insert_index, mod_line
        insert_index += mod_line.length
      end
    end
    return query
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
