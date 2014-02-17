class RemoveFeedIdFromApiKey < ActiveRecord::Migration
  def self.up
		remove_column :api_keys, :feed_id
  end

  def self.down
		add_column :api_keys, :feed_id, :integer
  end
end
