require 'oci8'

class CasyncInstance < ActiveRecord::Base
  attr_accessible :created_on, :succeeded, :message, :n_calls_inserted, :n_calls_updated, :calls_inserted, :calls_updated

  def max_attempts
      0
  end

  def sync_with_ca(casync_configuration)
    begin
      # Read query from file and customize it
      query = File.read('plugins/casync/query.sql')
      mod_query = customize_query(query)

      # Connect to database and execute modified query
      conn = OCI8.new(casync_configuration.db_user, casync_configuration.db_password, casync_configuration.db_url)
      cursor = conn.exec(mod_query)

      # Verify all necessary custom fields were created
      verify_custom_fields

      # Query to find all projects with HabilitarCASync field set to true
      projects = Project.where(:id => ProjectCustomField.where(:name => 'HabilitarCaSync').first.custom_values.where(:value => 1).select(:customized_id))
      # Query to find ArvoreSistemas field of project with CASync enabled
      projects_arvore_sistema = ProjectCustomField.where(:name => 'ArvoreSistemaRaiz').first.custom_values.where(:customized_id => projects).select([:customized_id, :value])
      #
      # Get last syncronization from db
      last_sync = CasyncInstance.order("created_on DESC").limit(1).first

      # Initialize attributes of current instance being processed
      self.n_calls_inserted = 0
      self.n_calls_updated = 0
      calls_inserted = []
      calls_updated = []

      # Go through all calls
      while call = cursor.fetch_hash

        # Get corresponding issue if existent
        call_issue = get_corresponding_issue call

        # If there is no issue associated, create a new issue
        if call_issue.nil?
          # Create issue for this call
          create_issue(call, projects_arvore_sistema, casync_configuration.redmine_user_id)

          # Update sync instance to include a newly inserted call
          self.n_calls_inserted += 1
          calls_inserted.push call["Chamado"]

          # Update call issue if it already exists and the call was modified
          # after last sync
        elsif !last_sync || call['DataMod'] > last_sync.created_on
          # Update issue for this call
          update_issue call_issue, call

          # Update sync instance to include a newly updated call
          self.n_calls_updated += 1
          calls_updated.push call["Chamado"]
        end
      end

      # Convert calls inserted and updated to string format and save sync
      self.calls_inserted = calls_inserted.join(',')
      self.calls_updated = calls_updated.join(',')
      self.succeeded = true
      save
    rescue => error
      # Guarantee some variables were initialized
      calls_inserted = [] if calls_inserted.nil?
      calls_updated = [] if calls_updated.nil?

      # Update CasyncInstance with fail message
      self.calls_inserted = calls_inserted.join(',')
      self.calls_updated = calls_updated.join(',')
      self.succeeded = false
      self.message = error.message
      save
      raise error
    ensure
      # Guarantee connection to db will be closed
      if defined?(cursor)
        cursor.close unless cursor.nil?
      end
      if defined?(conn)
        conn.logoff unless conn.nil?
      end
    end
  end

  # Receives a query and change it to lookup for all 'ArvoreSistemas' defined in projects
  def customize_query(query)
    # Query to find all projects with HabilitarCASync field set to true
    projects = Project.where(:id => ProjectCustomField.where(:name => 'HabilitarCaSync').first.custom_values.where(:value => 1).select(:customized_id))

    # Query to find ArvoreSistemaRaiz field of project with CASync enabled
    arvores_values = ProjectCustomField.where(:name => 'ArvoreSistemaRaiz').first.custom_values.where(:customized_id => projects).select(:value)
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

  def get_corresponding_issue(call)
    # Check for call custom field
    call_custom_field = IssueCustomField.where(:name => 'Chamado').first

    # Check if there's any issue with the same value for the 'Chamado' custom field as the call
    call_custom_value = CustomValue.where(:custom_field_id => call_custom_field.id, :value => call["Chamado"]).first

    # Get corresponding issue or nil if there's none
    if call_custom_value then Issue.find(call_custom_value.customized_id) else nil end
  end

  def verify_custom_fields
    # Get all tasks custom fields and raise error if they don't exist
    enable_custom_field = ProjectCustomField.where(:name => 'HabilitarCaSync').first
    raise "No project custom field named 'HabilitarCaSync'" if enable_custom_field.nil?

    tree_custom_field = ProjectCustomField.where(:name => 'ArvoreSistemaRaiz').first
    raise "No project custom field named 'ArvoreSistemaRaiz'" if tree_custom_field.nil?

    call_custom_field = IssueCustomField.where(:name => 'Chamado').first
    raise "No issue custom field named 'Chamado'" if call_custom_field.nil?

    tree_custom_field = IssueCustomField.where(:name => 'ArvoreSistema').first
    raise "No issue custom field named 'ArvoreSistema'" if tree_custom_field.nil?

    applicant_custom_field = IssueCustomField.where(:name => 'Solicitante').first
    raise "No issue custom field named 'Solicitante'" if applicant_custom_field.nil?

    user_custom_field = IssueCustomField.where(:name => 'UsuarioAfetado').first
    raise "No issue custom field named 'UsuarioAfetado'" if user_custom_field.nil?

    group_custom_field = IssueCustomField.where(:name => 'Grupo').first
    raise "No issue custom field named 'Grupo'" if group_custom_field.nil?
  end

  def update_custom_fields(issue, fields)
    f_id = Hash.new { |hash, key| hash[key] = nil }
    issue.available_custom_fields.each_with_index.map { |f,indx| f_id[f.name] = f.id }
    field_list = []
    fields.each do |name, value|
      field_id = f_id[name].to_s
      field_list << Hash[field_id, value]
    end
    issue.custom_field_values = field_list.reduce({},:merge)

    raise issue.errors.full_messages.join(', ') unless issue.save
  end

  # Find project where issue will be created based on ArvoreSistema field
  def find_equivalent_project(call, projects_arvore_sistema)
    # Variables that will store best project match
    candidate_project = nil
    candidate_length = 0

    projects_arvore_sistema.each do |project|
      arvore_sistema = project.value

      if arvore_sistema.end_with?("%")

        # Get best match for call's ArvoreSistema in projects
        arvore_sistema = arvore_sistema.chomp("%")

        # Best match will be the largest project's ArvoreSistema that occurs in beggining of call's ArvoreSistema
        if call['ArvoreSistema'].start_with?(arvore_sistema) && arvore_sistema.length > candidate_length
          candidate_project = project.customized_id
          candidate_length = arvore_sistema.length
        end
      else
        # Look for exact match and break if there is no % at end of project's ArvoreSistema
        if call['ArvoreSistema'] == arvore_sistema
          candidate_project = project.customized_id
          break
        end
      end
    end
    # Raise error if a candidate project wasn't found
    raise "There is no equivalent Project for Chamado=" + call["Chamado"] + " and ArvoreSistema=" + call["ArvoreSistema"] if candidate_project.nil?
    return candidate_project
  end

  def create_issue(call, projects_arvore_sistema, redmine_user_id)
    # Create new issue
    new_issue = Issue.create(
        :subject => call['Titulo'],
        # :description => call['Descricao'].read,
        :status_id => IssueStatus.where(:name => "To Do - Ready").first.id,
        :tracker_id => Tracker.where(:name => "História").first.id,
        :author_id => redmine_user_id,
        :project_id => find_equivalent_project(call, projects_arvore_sistema)
    )
    update_custom_fields(new_issue,
                         "Chamado" => call["Chamado"],
                         "Solicitante" => call["Solicitante"],
                         "UsuarioAfetado" => call["UsuarioAfetado"],
                         "ArvoreSistema" => call["ArvoreSistema"],
                         "Grupo" => call["Grupo"]
    )
  end

  def update_issue(issue, call)
    # Change issue fields that were changed in call
    issue.subject = call['Titulo'] if issue.subject != call['Titulo']
    # issue.description = call['Descricao'].read if issue.description != call['Descricao'].read
    update_custom_fields(issue,
                         "Chamado" => call["Chamado"],
                         "Solicitante" => call["Solicitante"],
                         "UsuarioAfetado" => call["UsuarioAfetado"],
                         "ArvoreSistema" => call["ArvoreSistema"],
                         "Grupo" => call["Grupo"]
    )
  end
end
