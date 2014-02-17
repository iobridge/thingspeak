class AddLocationToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :location, :string, :after => :elevation
  end

  def self.down
    remove_column :feeds, :location
  end
end
