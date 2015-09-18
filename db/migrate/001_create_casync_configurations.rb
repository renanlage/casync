class CreateCasyncConfigurations < ActiveRecord::Migration
  def change
    create_table :casync_configurations do |t|
      t.string :db_url
      t.string :db_user
      t.string :db_password
      t.string :redmine_user_id
      t.integer :frequency
      t.boolean :active, :default => false
    end
  end
end
