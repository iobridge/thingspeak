class AddDoubleIndexToFeeds < ActiveRecord::Migration
  def self.up
		remove_index :feeds, :channel_id
		remove_index :feeds, :created_at
		add_index :feeds, [:channel_id, :created_at]
  end

  def self.down
		remove_index :feeds, [:channel_id, :created_at]
		add_index :feeds, :channel_id
		add_index :feeds, :created_at
  end
end
