class AddMetadataToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :metadata, :text
  end
end

