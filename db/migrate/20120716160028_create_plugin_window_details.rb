class CreatePluginWindowDetails < ActiveRecord::Migration
  def self.up
    create_table :plugin_window_details do |t|
      t.integer :plugin_id
      t.integer :plugin_window_id

      t.timestamps
    end
  end

  def self.down
    drop_table :plugin_window_details
  end
end
