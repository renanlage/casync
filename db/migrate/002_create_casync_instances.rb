class CreateCasyncInstances < ActiveRecord::Migration
  def change
    create_table :casync_instances do |t|
      t.timestamp :created_on
      t.boolean :succeeded
      t.string :message
      t.integer :n_calls_inserted
      t.integer :n_calls_updated
      t.string :calls_inserted, :default => ''
      t.string :calls_updated, :default => ''
    end
    add_index :casync_instances, :created_on
  end
end
