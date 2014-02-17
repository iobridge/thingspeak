class AddGeolocationToFeed < ActiveRecord::Migration
  def self.up
		add_column :feeds, :latitude, :decimal, :precision => 15, :scale => 10
		add_column :feeds, :longitude, :decimal, :precision => 15, :scale => 10
		add_column :feeds, :elevation, :string
  end

  def self.down
		remove_column :feeds, :latitude
		remove_column :feeds, :longitude
		remove_column :feeds, :elevation
  end
end
