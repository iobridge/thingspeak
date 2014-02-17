class RemovePluginIdFromWindow < ActiveRecord::Migration
  def self.up
    remove_column :windows, :plugin_id
  end

  def self.down
    add_column :windows, :plugin_id, :string
  end
end
