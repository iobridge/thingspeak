class DropOldWindowTables < ActiveRecord::Migration
  def change
    drop_table :chart_window_details
    drop_table :plugin_window_details
    drop_table :portlet_window_details
  end
end

