class CreateWindows < ActiveRecord::Migration
  def self.up
    create_table :windows do |t|
      t.integer :channel_id
      t.integer :plugin_id
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :windows
  end
end
