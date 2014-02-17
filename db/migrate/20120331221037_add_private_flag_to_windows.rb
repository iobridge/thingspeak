class AddPrivateFlagToWindows < ActiveRecord::Migration
  def self.up
    add_column :windows, :private_flag, :boolean, :default => false
  end

  def self.down
    remove_column :windows, :private_flag
  end
end
