class AddClearingFlagToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :clearing, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :channels, :clearing
  end
end
