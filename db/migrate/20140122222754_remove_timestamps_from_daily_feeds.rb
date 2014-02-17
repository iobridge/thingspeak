class RemoveTimestampsFromDailyFeeds < ActiveRecord::Migration
  def up
    remove_column :daily_feeds, :created_at
    remove_column :daily_feeds, :updated_at
  end

  def down
    add_column :daily_feeds, :created_at, :datetime
    add_column :daily_feeds, :updated_at, :datetime
  end
end

