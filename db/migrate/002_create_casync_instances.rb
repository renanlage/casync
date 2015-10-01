class CreateCasyncInstances < ActiveRecord::Migration
  def change
    create_table :casync_instances do |t|
      t.timestamp :created_on
      t.boolean :succeeded
      t.text :message
      t.integer :n_calls_inserted, :default => 0
      t.integer :n_calls_updated, :default => 0
      t.text :calls_inserted
      t.text :calls_updated
    end
    add_index :casync_instances, :created_on
  end
end
