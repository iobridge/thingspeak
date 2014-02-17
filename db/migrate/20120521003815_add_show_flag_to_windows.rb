class AddShowFlagToWindows < ActiveRecord::Migration
  def self.up
    add_column :windows, :show_flag, :boolean, :default => true
  end

  def self.down
    remove_column :windows, :show_flag
  end
end
