class RemoveRawDataFromFeeds < ActiveRecord::Migration
  def change
    remove_column :feeds, :raw_data
  end
end

