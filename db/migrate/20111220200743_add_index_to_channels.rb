class AddIndexToChannels < ActiveRecord::Migration
  def self.up
    add_index :channels, :user_id
    add_index :channels, [:public_flag, :last_entry_id, :updated_at], :name => 'channels_public_viewable'
  end

  def self.down
    remove_index :channels, :user_id
    remove_index :channels, :name => 'channels_public_viewable'
  end
end
