class AddGeolocationIndexToChannels < ActiveRecord::Migration
  def change
    add_index :channels, [:latitude, :longitude]
  end
end

