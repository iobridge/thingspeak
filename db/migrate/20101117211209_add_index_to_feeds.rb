class AddIndexToFeeds < ActiveRecord::Migration
  def self.up
		add_index :feeds, :device_id
  end

  def self.down
		remove_index :feeds, :device_id
  end
end
