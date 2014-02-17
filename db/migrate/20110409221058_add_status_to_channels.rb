class AddStatusToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :status, :string
  end

  def self.down
    remove_column :channels, :status
  end
end
