class AddEntryIdToFeeds < ActiveRecord::Migration
  def self.up
		add_column :feeds, :entry_id, :integer
  end

  def self.down
		remove_column :feeds, :entry_id
  end
end
