class AddChannelIdEntryIdIndexToFeeds < ActiveRecord::Migration
  def self.up
		add_index :feeds, [:channel_id, :entry_id]
  end

  def self.down
		remove_index :feeds, [:channel_id, :entry_id]
  end
end
