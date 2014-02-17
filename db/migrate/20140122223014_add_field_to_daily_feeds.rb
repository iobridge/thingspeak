class AddFieldToDailyFeeds < ActiveRecord::Migration
  def change
    add_column :daily_feeds, :field, :integer, :limit => 1
  end
end

