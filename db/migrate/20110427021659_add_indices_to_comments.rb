class AddIndicesToComments < ActiveRecord::Migration
  def self.up
    add_index :comments, :channel_id
  end

  def self.down
    remove_index :comments, :channel_id
  end
end
