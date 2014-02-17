class AddCreatedAtIndexToFeeds < ActiveRecord::Migration
  def self.up
		add_index :feeds, :created_at
  end

  def self.down
		remove_index :feeds, :created_at
  end
end
