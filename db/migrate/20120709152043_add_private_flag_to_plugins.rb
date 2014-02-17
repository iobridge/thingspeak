class AddPrivateFlagToPlugins < ActiveRecord::Migration
  def self.up
    add_column :plugins, :private_flag, :boolean, :default => true
  end

  def self.down
    remove_column :plugins, :private_flag
  end
end
