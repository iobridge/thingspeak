class AddVideoFieldsToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :video_id, :string
    add_column :channels, :video_type, :string
  end

  def self.down
    remove_column :channels, :video_id
    remove_column :channels, :video_type
  end
end
