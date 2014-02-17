class AddIndexToPluginWindowDetails < ActiveRecord::Migration
  def change
    add_index :plugin_window_details, :plugin_window_id
  end
end

