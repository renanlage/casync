class CreateCaSyncConfigurations < ActiveRecord::Migration
  def change
    create_table :ca_sync_configurations do |t|
      t.string :db_url
      t.string :db_user
      t.string :db_password
      t.integer :frequency
      t.string :redmine_user_id
    end
    add_index :ca_sync_configurations, :frequency
  end
end
