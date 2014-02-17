class AddChannelIdToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :channel_id, :integer
  end

  def self.down
    remove_column :comments, :channel_id
  end
end
